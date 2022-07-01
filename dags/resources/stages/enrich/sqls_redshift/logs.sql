INSERT INTO {{params.schema}}.{{params.table}}
(
  chain_id,
  log_index,
  transaction_hash,
  transaction_index,
  address,
  data,
  topic0,
  topic1,
  topic2,
  topic3,
  block_number,
  block_hash,
  block_timestamp
)
SELECT
    1 as chain_id,
    logs.log_index,
    logs.transaction_hash,
    logs.transaction_index,
    logs.address,
    logs.data,
    json_extract_array_element_text(topics,0,true) AS topic0,
    json_extract_array_element_text(topics,1,true) AS topic1,
    json_extract_array_element_text(topics,2,true) AS topic2,
    json_extract_array_element_text(topics,3,true) AS topic3,
    blocks.number AS block_number,
    blocks.hash AS block_hash,
    (TIMESTAMP 'epoch' + blocks.timestamp * INTERVAL '1 Second ') AS block_timestamp
FROM {{params.schema}}.blocks AS blocks
    JOIN {{params.schema}}.logs AS logs ON blocks.number = logs.block_number
where date(TIMESTAMP 'epoch' + blocks.timestamp * INTERVAL '1 Second ') = '{{ds}}';
