SELECT
    token_transfers_v2.contract_address,
    token_transfers_v2.from_address,
    token_transfers_v2.to_address,
    token_transfers_v2.amount,
    token_transfers_v2.token_type,
    token_transfers_v2.token_ids,
    token_transfers_v2.transaction_hash,
    token_transfers_v2.log_index,
    TIMESTAMP_SECONDS(blocks.timestamp) AS block_timestamp,
    blocks.number AS block_number,
    blocks.hash AS block_hash
FROM {{params.dataset_name_raw}}.blocks AS blocks
    JOIN {{params.dataset_name_raw}}.token_transfers_v2 AS token_transfers_v2 ON blocks.number = token_transfers_v2.block_number
where true
    {% if not params.load_all_partitions %}
    and date(timestamp_seconds(blocks.timestamp)) = '{{ds}}'
    {% endif %}