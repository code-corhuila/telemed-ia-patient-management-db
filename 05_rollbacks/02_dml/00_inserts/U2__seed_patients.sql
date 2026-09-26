-- =====================================================================
-- TeleMed IA — Patient Management DEV/TEST Seed Data
-- =====================================================================
-- Rollback: U2__seed_patients.sql
-- =====================================================================
-- Reverts the DEV/TEST seed data inserted by V002__seed_patients.sql.
----------------------------------------------------------------------

-- NOTE:
-- This seed is not a Flyway migration. It is executed by the
-- docker-compose `seed` service after Flyway creates the schema.
-- It is intended exclusively for DEV/TEST environments.
--------------------------------------------------------

-- The records are identified by their user_id values, which are the
-- external identifiers used by the seed data.
-- =====================================================================

DELETE FROM patients
WHERE user_id IN (1001, 1002);
