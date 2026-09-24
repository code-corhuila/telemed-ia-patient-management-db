-- =====================================================================
-- TeleMed IA — Patient Management Seed Data
-- Migration: V2__seed_test_data.sql
-- =====================================================================
-- NOTE: This migration inserts test data for local development and
--       integration testing only. It is idempotent and uses fixed
--       identifiers so it can run multiple times without error.
-- =====================================================================

INSERT INTO patients (id, user_id, birth_date, phone, medical_history, description)
VALUES
    (1, 1001, '1990-05-15', '3001234567', 'Hypertension, controlled with medication.', 'No known allergies.'),
    (2, 1002, '1985-11-03', '3007654321', 'Type 2 diabetes, diagnosed in 2018.', 'Allergic to penicillin.')
ON CONFLICT (id) DO NOTHING;

-- Reset the sequence so future inserts do not collide with seeded ids.
SELECT setval(
    pg_get_serial_sequence('patients', 'id'),
    GREATEST((SELECT MAX(id) FROM patients), 1)
);