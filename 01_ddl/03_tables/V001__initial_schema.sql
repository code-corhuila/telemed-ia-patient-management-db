-- =====================================================================
-- TeleMed IA — Patient Management Schema
-- Migration: V1__initial_schema.sql
-- =====================================================================
-- NOTE: Migrations assume a clean slate. Do not use IF NOT EXISTS here:
--       if the table already exists with a different shape (manual
--       intervention, partial deploy), the migration must fail loudly
--       rather than silently succeed with a wrong schema.
-- =====================================================================

CREATE TABLE patients (
    id              BIGSERIAL    PRIMARY KEY,
    user_id         BIGINT       NOT NULL,
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
COMMENT ON COLUMN patients.user_id IS 'External reference to auth-service user id. Unique among active records.';
COMMENT ON COLUMN patients.birth_date IS 'Patient date of birth. Must not be in the future.';
COMMENT ON COLUMN patients.phone IS 'Contact phone number. Free format.';
COMMENT ON COLUMN patients.medical_history IS 'Free-text medical history provided by the patient.';
COMMENT ON COLUMN patients.description IS 'Additional patient description or notes.';
COMMENT ON COLUMN patients.created_at IS 'Record creation timestamp (with timezone).';
COMMENT ON COLUMN patients.updated_at IS 'Last modification timestamp. Maintained by the trg_patients_updated_at trigger.';
COMMENT ON COLUMN patients.deleted_at IS 'Soft delete marker. NULL means the record is active.';

-- Partial unique index: prevents two ACTIVE patient records from sharing the
-- same user_id. Soft-deleted records (deleted_at IS NOT NULL) are excluded,
-- allowing the same auth-service user to be re-onboarded later.
CREATE UNIQUE INDEX idx_patients_user_id_active
    ON patients (user_id)
    WHERE deleted_at IS NULL;

-- Index for filtering active records.
CREATE INDEX idx_patients_deleted
    ON patients (deleted_at)
    WHERE deleted_at IS NULL;

-- Constraint: birth_date must not be in the future.
ALTER TABLE patients
    ADD CONSTRAINT chk_patients_birth_date_not_future
    CHECK (birth_date IS NULL OR birth_date <= CURRENT_DATE);

-- Trigger function: keep updated_at in sync on every UPDATE.
-- This guarantees the audit trail even if an application code path forgets
-- to set the column explicitly.
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_patients_updated_at
    BEFORE UPDATE ON patients
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();