merge `{{params.destination_dataset_project_id}}.{{params.destination_dataset_name}}.token_transfers_v2` dest
using {{params.dataset_name_temp}}.{{params.source_table}} source
on false
when not matched and date(block_timestamp) = '{{ds}}' then
insert (
    contract_address,
    from_address,
    to_address,
    amount,
    token_type,
    token_ids,
    transaction_hash,
    log_index,
    block_timestamp,
    block_number,
    block_hash
) values (
    contract_address,
    from_address,
    to_address,
    amount,
    token_type,
    token_ids,
    transaction_hash,
    log_index,
    block_timestamp,
    block_number,
    block_hash
)
when not matched by source and date(block_timestamp) = '{{ds}}' then
delete
