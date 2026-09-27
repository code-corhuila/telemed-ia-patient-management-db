-- V003__create_idempotency_key.sql
-- Backing table for idempotent creation (norma 5.3.8).
--
-- The service inserts the resource and the idempotency key in the same
-- transaction; a repeated request with the same key returns the original
-- resource instead of creating a second one.

CREATE TABLE idempotency_key (
    key         text        NOT NULL,
    user_id     bigint      NOT NULL,
    resource_id bigint      NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_idempotency_key PRIMARY KEY (key),
    CONSTRAINT chk_idempotency_key_length
        CHECK (char_length(key) BETWEEN 8 AND 128)
);

CREATE INDEX idx_idempotency_key_created_at
    ON idempotency_key (created_at);