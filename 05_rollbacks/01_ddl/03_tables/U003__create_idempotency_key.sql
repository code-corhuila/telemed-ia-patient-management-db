-- U003__create_idempotency_key.sql
-- Reversal of V003.

DROP INDEX IF EXISTS idx_idempotency_key_created_at;
DROP TABLE IF EXISTS idempotency_key;