from __future__ import print_function
from heapq import merge

import json
import logging
import os
import time
from datetime import datetime, timedelta

from airflow import models
from airflow.hooks.postgres_hook import PostgresHook
from airflow.operators.python_operator import PythonOperator
from ethereumetl_airflow.utils.template_utils import render_template

logging.basicConfig()
logging.getLogger().setLevel(logging.DEBUG)


def build_load_dag_redshift(
        dag_id,
        output_bucket,
        aws_access_key_id,
        aws_secret_access_key,
        chain='ethereum',
        notification_emails=None,
        start_date=datetime(2020, 12, 31),
        schedule_interval='0 0 * * *'
):
    default_dag_args = {
        'depends_on_past': False,
        'start_date': start_date,
        'email_on_failure': True,
        'email_on_retry': True,
        'retries': 5,
        'retry_delay': timedelta(minutes=5)
    }

    if notification_emails and len(notification_emails) > 0:
        default_dag_args['email'] = [email.strip() for email in notification_emails.split(',')]

    # Define a DAG (directed acyclic graph) of tasks.
    dag = models.DAG(
        dag_id=dag_id,
        # Daily at 1:30am
        schedule_interval=schedule_interval,
        max_active_runs=5,
        default_args=default_dag_args)
    
    dags_folder = os.environ.get('DAGS_FOLDER', '/usr/local/airflow/dags')

    def add_load_tasks(task, file_format):
        if output_bucket is None:
            raise ValueError('You must set OUTPUT_BUCKET environment variable')

        load_operator = PythonOperator(
            task_id='s3_to_redshift_{task}'.format(task=task),
            dag=dag,
            python_callable=load_task,
            provide_context=True,
            op_kwargs={
                'conn_id': 'redshift',
                'file_format': file_format,
                'task': task
            },
        )
        return load_operator

    def read_file(filepath):
        with open(filepath) as file_handle:
            content = file_handle.read()
            return content

    def load_task(ds, **kwargs):
        conn_id = kwargs.get('conn_id')
        file_format = kwargs.get('file_format')
        task = kwargs.get('task')
        pg_hook = PostgresHook(conn_id)

        table_partition_keys = {
            'blocks': 'number',
            'contracts': 'address',
            'logs': 'block_number',
            'receipts': 'block_number',
            'token_transfers': 'block_number',
            'token_transfers_v2': 'block_number',
            'tokens': 'address',
            'traces': 'block_number',
            'transactions': 'block_number'
        }

        sql = """
            DROP TABLE IF EXISTS {schema}.{table}_copy_tmp;
    
            CREATE TABLE {schema}.{table}_copy_tmp
            (LIKE {schema}.{table});
        """

        if file_format == 'csv':
            sql += """
                COPY {schema}.{table}_copy_tmp
                FROM 's3://{output_bucket}/export/{table}/block_date={date}/{table}.{file_format}'
                WITH CREDENTIALS
                'aws_access_key_id={aws_access_key_id};aws_secret_access_key={aws_secret_access_key}'
                TRUNCATECOLUMNS BLANKSASNULL EMPTYASNULL IGNOREHEADER 1 CSV;
            """
        elif file_format == 'json':
            sql += """
                COPY {schema}.{table}_copy_tmp
                FROM 's3://{output_bucket}/export/{table}/block_date={date}/{table}.{file_format}'
                WITH CREDENTIALS
                'aws_access_key_id={aws_access_key_id};aws_secret_access_key={aws_secret_access_key}'
                TRUNCATECOLUMNS BLANKSASNULL EMPTYASNULL JSON 'auto';
            """
        else:
            raise ValueError('Only json and csv file formats are supported.')

        sql += """
            BEGIN TRANSACTION;
    
            DELETE FROM {schema}.{table}
            USING {schema}.{table}_copy_tmp
            WHERE
              {schema}.{table}.{partition_key} = {schema}.{table}_copy_tmp.{partition_key};
    
            INSERT INTO {schema}.{table}
            SELECT * FROM {schema}.{table}_copy_tmp;
    
            END TRANSACTION;
    
            DROP TABLE {schema}.{table}_copy_tmp;
        """

        formatted_sql = sql.format(
            schema=chain,
            table=task,
            partition_key=table_partition_keys[task],
            output_bucket=output_bucket,
            date=ds,
            file_format=file_format,
            aws_access_key_id=aws_access_key_id,
            aws_secret_access_key=aws_secret_access_key
        )
        pg_hook.run(formatted_sql)
    
    def add_enrich_tasks(task):
        if output_bucket is None:
            raise ValueError('You must set OUTPUT_BUCKET environment variable')

        load_operator = PythonOperator(
            task_id='{task}_enrich'.format(task=task),
            dag=dag,
            python_callable=enrich_task,
            provide_context=True,
            op_kwargs={
                'conn_id': 'redshift',
                'task': task,
            },
        )
        return load_operator
    
    def enrich_task(ds, **kwargs):
        template_context = kwargs.copy()
        template_context['ds'] = ds

        conn_id = kwargs.get('conn_id')
        task = kwargs.get('task')
        pg_hook = PostgresHook(conn_id)

        table_partition_keys = {
            'blocks_enrich': 'number',
            'contracts_enrich': 'address',
            'logs_enrich': 'block_number',
            'receipts_enrich': 'block_number',
            'token_transfer_enrich': 'block_number',
            'token_transfers_v2_enrich': 'block_number',
            'tokens_enrich': 'address',
            'traces_enrich': 'block_number',
            'transactions_enrich': 'block_number'
        }

        sql = """
            DROP TABLE IF EXISTS {schema}.{table}_copy_tmp;
    
            CREATE TABLE {schema}.{table}_copy_tmp
            (LIKE {schema}.{table});
        """

        merge_sql_path = os.path.join(
        dags_folder, 'resources/stages/enrich/sqls_redshift/{task}.sql'.format(task=task))
        merge_sql_template = read_file(merge_sql_path)

        merge_template_context = template_context.copy()
        merge_template_context['params']['schema'] = "{schema}"
        merge_template_context['params']['table'] = "{table}_copy_tmp"
        merge_sql = render_template(merge_sql_template, merge_template_context)
        
        sql += merge_sql

        sql += """
            BEGIN TRANSACTION;
    
            DELETE FROM {schema}.{table}
            USING {schema}.{table}_copy_tmp
            WHERE
              {schema}.{table}.{partition_key} = {schema}.{table}_copy_tmp.{partition_key};
    
            INSERT INTO {schema}.{table}
            SELECT * FROM {schema}.{table}_copy_tmp;
    
            END TRANSACTION;

            UNLOAD ('SELECT * FROM {schema}.{table}_copy_tmp')
            TO 's3://{output_bucket}/export/{table}/block_date={date}/{table}.csv'
            WITH CREDENTIALS
            'aws_access_key_id={aws_access_key_id};aws_secret_access_key={aws_secret_access_key}'
            CSV HEADER ALLOWOVERWRITE;
    
            DROP TABLE {schema}.{table}_copy_tmp;
        """
        print("Enrichment SQL")
        print(sql)

        table = '{task}_enrich'.format(task=task)
        formatted_sql = sql.format(
            schema=chain,
            table=table,
            partition_key=table_partition_keys[table],
            date=ds,
            output_bucket=output_bucket,
            aws_access_key_id=aws_access_key_id,
            aws_secret_access_key=aws_secret_access_key
        )
        pg_hook.run(formatted_sql)


    load_blocks_task = add_load_tasks('blocks', 'json')
    load_transactions_task = add_load_tasks('transactions', 'json')
    load_receipts_task = add_load_tasks('receipts', 'json')
    load_logs_task = add_load_tasks('logs', 'json')
    load_contracts_task = add_load_tasks('contracts', 'json')
    load_tokens_task = add_load_tasks('tokens', 'json')
    load_token_transfers_task = add_load_tasks('token_transfers', 'json')
    #load_token_transfers_v2_task = add_load_tasks('token_transfers_v2', 'json')
    #load_traces_task = add_load_tasks('traces', 'json')

    enrich_blocks_task = add_enrich_tasks('blocks')
    load_blocks_task >> enrich_blocks_task
    enrich_transactions_task = add_enrich_tasks('transactions')
    load_transactions_task >> enrich_transactions_task
    enrich_logs_task = add_enrich_tasks('logs')
    load_logs_task >> enrich_logs_task
    #enrich_token_transfers_v2_task = add_enrich_tasks('token_transfers')

    return dag
