-- The migration does NOT create a dedicated "patients" schema.
-- Therefore, no DROP SCHEMA statement is required here.
-- =====================================================================

DROP TRIGGER trg_patients_updated_at ON patients;

DROP FUNCTION set_updated_at();

DROP TABLE patients;