-- =====================================================================
-- TeleMed IA — Patient Management Schema
-- Migration: V1__initial_schema.sql
-- =====================================================================

-- Table: patients
-- Purpose: Stores patient profile information owned by the Patient Management
--          bounded context. The `user_id` column references the identity
--          service (auth-service). No foreign key crosses service boundaries.
-- =====================================================================

CREATE TABLE IF NOT EXISTS patients (
    id              BIGSERIAL    PRIMARY KEY,
    user_id         BIGINT       NOT NULL UNIQUE,
    birth_date      DATE,
    phone           VARCHAR(30),
    medical_history TEXT,
    description     TEXT,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

COMMENT ON TABLE  patients IS 'Patient profile owned by the Patient Management bounded context.';
COMMENT ON COLUMN patients.id IS 'Internal primary key of the patient record.';
COMMENT ON COLUMN patients.user_id IS 'External reference to auth-service user id. Unique per patient.';
COMMENT ON COLUMN patients.birth_date IS 'Patient date of birth. Must not be in the future.';
COMMENT ON COLUMN patients.phone IS 'Contact phone number. Free format.';
COMMENT ON COLUMN patients.medical_history IS 'Free-text medical history provided by the patient.';
COMMENT ON COLUMN patients.description IS 'Additional patient description or notes.';
COMMENT ON COLUMN patients.created_at IS 'Record creation timestamp (with timezone).';
COMMENT ON COLUMN patients.updated_at IS 'Last modification timestamp (with timezone).';
COMMENT ON COLUMN patients.deleted_at IS 'Soft delete marker. NULL means the record is active.';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_patients_user_id ON patients (user_id);
CREATE INDEX IF NOT EXISTS idx_patients_deleted ON patients (deleted_at) WHERE deleted_at IS NULL;

-- Constraint: birth_date must not be in the future
ALTER TABLE patients
    ADD CONSTRAINT chk_patients_birth_date_not_future
    CHECK (birth_date IS NULL OR birth_date <= CURRENT_DATE);