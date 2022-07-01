from airflow import DAG

from airflow.operators.bash_operator import BashOperator

from datetime import timedelta,time,datetime
import os

DAG_ID = os.path.basename(__file__).replace(".py", "")

default_args = {
            "owner": "airflow",
            "start_date": datetime(2020, 9, 9),
            "depends_on_past": False,
            "email_on_failure": False,
            "email_on_retry": False,
            "email": "infrastructure@bitski.com",
            "retries": 1,
            "retry_delay": timedelta(minutes=5)
        }

from time import sleep
from datetime import datetime
from random import random

#this is useful because the webserver can't install the requirements.txt dependencies so commands don't work directly through cli
#the workaround is to setup a dag which can make the cli calls so the calls are executed on the worker instead of webserver

with DAG(dag_id=DAG_ID, schedule_interval=None, default_args=default_args, catchup=False) as dag:
    cli_command = BashOperator(
        task_id="cli_command",
        bash_command="airflow {{ dag_run.conf['command'] }}"
    )
    cli_command
