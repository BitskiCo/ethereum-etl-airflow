INSERT INTO {{params.schema}}.{{params.table}}
(
  chain_id,
  from_address,
  to_address,
  contract_address,
  token_id,
  token_type,
  amount,
  transaction_hash,
  log_index,
  block_number,
  block_hash,
  block_timestamp
)
SELECT
    1 as chain_id,
    token_transfers_v2.contract_address,
    token_transfers_v2.from_address,
    token_transfers_v2.to_address,
    token_transfers_v2.amount,
    token_transfers_v2.token_type,
    token_transfers_v2.token_ids,
    token_transfers_v2.transaction_hash,
    token_transfers_v2.log_index,
    (TIMESTAMP 'epoch' + blocks.timestamp * INTERVAL '1 Second ') AS block_timestamp,
    blocks.number AS block_number,
    blocks.hash AS block_hash
FROM {{params.schema}}.blocks AS blocks
    JOIN {{params.schema}}.token_transfers_v2 AS token_transfers_v2 ON blocks.number = token_transfers_v2.block_number
where date(TIMESTAMP 'epoch' + blocks.timestamp * INTERVAL '1 Second ') = '{{ds}}';
