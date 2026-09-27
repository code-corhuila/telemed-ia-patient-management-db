-- =====================================================================
-- TeleMed IA — Patient Management DEV/TEST Seed Data
-- =====================================================================
-- NOTE: This file is NOT a Flyway migration. It is executed by the
--       docker-compose `seed` service AFTER Flyway has created the
--       schema. It never runs in qa, staging, or production.
-- =====================================================================

INSERT INTO patients (user_id, birth_date, phone, medical_history, description)
VALUES
    (1001, '1990-05-15', '3001234567', 'Hypertension, controlled with medication.', 'No known allergies.'),
    (1002, '1985-11-03', '3007654321', 'Type 2 diabetes, diagnosed in 2018.', 'Allergic to penicillin.')
ON CONFLICT DO NOTHING;