INSERT INTO {{params.schema}}.{{params.table}}
(
  chain_id,
  timestamp,
  number,
  hash,
  parent_hash,
  nonce,
  sha3_uncles,
  logs_bloom,
  transactions_root,
  state_root,
  receipts_root,
  miner,
  difficulty,
  total_difficulty,
  size,
  extra_data,
  gas_limit,
  gas_used ,
  transaction_count
)
SELECT
    1 AS chain_id,
    (TIMESTAMP 'epoch' + timestamp * INTERVAL '1 Second ') AS timestamp,
    blocks.number,
    blocks.hash,
    blocks.parent_hash,
    blocks.nonce,
    blocks.sha3_uncles,
    blocks.logs_bloom,
    blocks.transactions_root,
    blocks.state_root,
    blocks.receipts_root,
    blocks.miner,
    blocks.difficulty,
    blocks.total_difficulty,
    blocks.size,
    blocks.extra_data,
    blocks.gas_limit,
    blocks.gas_used,
    blocks.transaction_count
FROM {{params.schema}}.blocks AS blocks
where date(TIMESTAMP 'epoch' + timestamp * INTERVAL '1 Second ') = '{{ds}}';
