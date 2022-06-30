CREATE SCHEMA IF NOT EXISTS ethereum;

DROP TABLE IF EXISTS ethereum.blocks_enrich;

CREATE TABLE ethereum.blocks_enrich (
  chain_id          BIGINT         DEFAULT 1 NOT NULL,     -- Chain ID of network
  timestamp         TIMESTAMP      NOT NULL,     -- The unix timestamp for when the block was collated
  number            BIGINT         NOT NULL,     -- The block number
  hash              VARCHAR(65535) NOT NULL,     -- Hash of the block
  parent_hash       VARCHAR(65535) NOT NULL,     -- Hash of the parent block
  nonce             VARCHAR(65535) NOT NULL,     -- Hash of the generated proof-of-work
  sha3_uncles       VARCHAR(65535) NOT NULL,     -- SHA3 of the uncles data in the block
  logs_bloom        VARCHAR(65535) NOT NULL,     -- The bloom filter for the logs of the block
  transactions_root VARCHAR(65535) NOT NULL,     -- The root of the transaction trie of the block
  state_root        VARCHAR(65535) NOT NULL,     -- The root of the final state trie of the block
  receipts_root     VARCHAR(65535) NOT NULL,     -- The root of the receipts trie of the block
  miner             VARCHAR(65535) NOT NULL,     -- The address of the beneficiary to whom the mining rewards were given
  difficulty        NUMERIC(38, 0) NOT NULL,     -- Integer of the difficulty for this block
  total_difficulty  NUMERIC(38, 0) NOT NULL,     -- Integer of the total difficulty of the chain until this block
  size              BIGINT         NOT NULL,     -- The size of this block in bytes
  extra_data        VARCHAR(65535) DEFAULT NULL, -- The extra data field of this block
  gas_limit         BIGINT         DEFAULT NULL, -- The maximum gas allowed in this block
  gas_used          BIGINT         DEFAULT NULL, -- The total used gas by all transactions in this block
  transaction_count BIGINT         NOT NULL,
  base_fee_per_gas  BIGINT         DEFAULT NULL,
  PRIMARY KEY (chain_id, number)
)
DISTKEY (number)
SORTKEY (chain_id, timestamp);

--

DROP TABLE IF EXISTS ethereum.logs_enrich;

CREATE TABLE ethereum.logs_enrich (
  chain_id          BIGINT         DEFAULT 1 NOT NULL,     -- Chain ID of network
  log_index         BIGINT         NOT NULL,     -- Integer of the log index position in the block
  transaction_hash  VARCHAR(65535) NOT NULL,     -- Hash of the transactions this log was created from
  transaction_index BIGINT         NOT NULL,     -- Integer of the transactions index position log was created from
  address           VARCHAR(65535) NOT NULL,     -- Address from which this log originated
  data              VARCHAR(65535) NOT NULL,     -- Contains one or more 32 Bytes non-indexed arguments of the log
  topic0            VARCHAR(65535) NOT NULL,     -- Indexed log arguments (0 to 4 32-byte hex strings). (In solidity: The first topic is the hash of the signature of the event (e.g. Deposit(address,bytes32,uint256)), except you declared the event with the anonymous specifier
  topic1            VARCHAR(65535) NOT NULL,     -- Indexed log arguments (0 to 4 32-byte hex strings)
  topic2            VARCHAR(65535) NOT NULL,     -- Indexed log arguments (0 to 4 32-byte hex strings)
  topic3            VARCHAR(65535) NOT NULL,     -- Indexed log arguments (0 to 4 32-byte hex strings)
  block_number      BIGINT         NOT NULL,     -- The block number where this log was in
  block_hash        VARCHAR(65535) NOT NULL,     -- Hash of the block where this log was in
  block_timestamp   TIMESTAMP      NOT NULL,     -- The block timestamp where this log was in
  PRIMARY KEY (chain_id, transaction_hash, log_index)
)
DISTKEY (block_number)
SORTKEY (chain_id, block_timestamp);

--

DROP TABLE IF EXISTS ethereum.transactions_enrich;

CREATE TABLE ethereum.transactions_enrich (
  chain_id                    BIGINT         DEFAULT 1 NOT NULL,     -- Chain ID of network
  hash                        VARCHAR(65535) NOT NULL,     -- Hash of the transaction
  nonce                       BIGINT         NOT NULL,     -- The number of transactions made by the sender prior to this one
  transaction_index           BIGINT         NOT NULL,     -- Integer of the transactions index position in the block
  from_address                VARCHAR(65535) NOT NULL,     -- Address of the sender
  to_address                  VARCHAR(65535) DEFAULT NULL, -- Address of the receiver. null when its a contract creation transaction
  value                       NUMERIC(38, 0) NOT NULL,     -- Value transferred in Wei
  gas                         BIGINT         NOT NULL,     -- Gas provided by the sender
  gas_price                   BIGINT         NOT NULL,     -- Gas price provided by the sender in Wei
  input                       VARCHAR(65535) NOT NULL,     -- The data sent along with the transaction
  block_hash                  VARCHAR(65535) NOT NULL,     -- Hash of the block where this transaction was in
  block_number                BIGINT         NOT NULL,     -- Block number where this transaction was in
  block_timestamp             TIMESTAMP      NOT NULL,
  receipt_cumulative_gas_used BIGINT         NOT NULL,
  receipt_gas_used            BIGINT         NOT NULL,
  receipt_contract_address    VARCHAR(65535) DEFAULT NULL,
  receipt_root                VARCHAR(65535) DEFAULT NULL,
  receipt_status              BIGINT         DEFAULT NULL,
  max_fee_per_gas             BIGINT         DEFAULT NULL,
  max_priority_fee_per_gas    BIGINT         DEFAULT NULL,
  transaction_type            BIGINT         DEFAULT NULL,
  receipt_effective_gas_price BIGINT         DEFAULT NULL,
  PRIMARY KEY (chain_id, hash)
)
DISTKEY (block_number)
SORTKEY (chain_id, block_timestamp);

--

DROP TABLE IF EXISTS ethereum.token_transfers_v2_enrich;

CREATE TABLE ethereum.token_transfers_v2_enrich (
  chain_id         BIGINT         DEFAULT 1 NOT NULL, -- Chain ID of network
  from_address     VARCHAR(65535) NOT NULL, -- Address of the sender
  to_address       VARCHAR(65535) NOT NULL, -- Address of the receiver
  contract_address VARCHAR(65535) NOT NULL, -- Contract address
  token_id         VARCHAR(65535) NOT NULL, -- id of the token transferred (ERC721)
  token_type       VARCHAR(65535) NOT NULL, -- ERC20/ ERC1155/ ERC721
  amount           VARCHAR(65535) NOT NULL, -- Amount of tokens transferred (ERC20) / id of the token transferred (ERC721). Cast to NUMERIC or FLOAT8
  transaction_hash VARCHAR(65535) NOT NULL, -- Transaction hash
  log_index        BIGINT         NOT NULL, -- Log index in the transaction receipt
  block_number     BIGINT         NOT NULL, -- The block number
  block_hash       VARCHAR(65535) NOT NULL, -- Hash of the block where this log was in
  block_timestamp  TIMESTAMP      NOT NULL, -- The block timestamp where this log was in
  PRIMARY KEY (chain_id, transaction_hash, log_index, token_id)
)
DISTKEY (block_number)
SORTKEY (chain_id, log_index);
