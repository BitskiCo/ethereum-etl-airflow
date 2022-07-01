INSERT INTO {{params.schema}}.{{params.table}}
(
  chain_id,
  hash,
  nonce,
  transaction_index,
  from_address,
  to_address,
  value,
  gas,
  gas_price,
  input,
  receipt_cumulative_gas_used,
  receipt_gas_used,
  receipt_contract_address,
  receipt_root,
  receipt_status,
  block_number,
  block_hash,
  block_timestamp
)
SELECT
    1 as chain_id,
    transactions.hash,
    transactions.nonce,
    transactions.transaction_index,
    transactions.from_address,
    transactions.to_address,
    transactions.value,
    transactions.gas,
    transactions.gas_price,
    transactions.input,
    receipts.cumulative_gas_used AS receipt_cumulative_gas_used,
    receipts.gas_used AS receipt_gas_used,
    receipts.contract_address AS receipt_contract_address,
    receipts.root AS receipt_root,
    receipts.status AS receipt_status,
    blocks.number AS block_number,
    blocks.hash AS block_hash,
    (TIMESTAMP 'epoch' + blocks.timestamp * INTERVAL '1 Second ') AS block_timestamp
FROM {{params.schema}}.blocks AS blocks
    JOIN {{params.schema}}.transactions AS transactions ON blocks.number = transactions.block_number
    JOIN {{params.schema}}.receipts AS receipts ON transactions.hash = receipts.transaction_hash
where date(TIMESTAMP 'epoch' + blocks.timestamp * INTERVAL '1 Second ') = '{{ds}}';

