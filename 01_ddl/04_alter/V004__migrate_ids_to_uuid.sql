-- =====================================================================
-- TeleMed IA — Patient Management Schema
-- Migration: V004__migrate_ids_to_uuid.sql
-- =====================================================================
-- Migrates patient identifiers to UUID, aligned with:
--   - identity-and-access (JWT `sub` is a UUID)
--   - appointment-scheduling-db (V009 migrated to UUID)
--   - medical-consultation-db (V011, V012 migrated to UUID)
--   - course rule: "camelCase JSON and UUID ids"
--
-- Columns migrated:
--   patients.id           BIGSERIAL -> uuid
--   patients.user_id      BIGINT    -> uuid
--   idempotency_key.user_id      BIGINT -> uuid
--   idempotency_key.resource_id  BIGINT -> uuid
--
-- Data preservation:
--   - the dev seed (V002) uses user_id 1001 and 1002; both are translated
--     to deterministic UUIDs so that integration tests and local QA keep
--     working with stable identifiers:
--         1001 -> 00000000-0000-0000-0000-000000001001
--         1002 -> 00000000-0000-0000-0000-000000001002
--   - any other row receives gen_random_uuid()
--   - idempotency_key has no seed; resource_id receives gen_random_uuid()
--     (the previous numeric values cannot be mapped back to the new UUIDs)
--
-- Rollback: see 05_rollbacks/01_ddl/04_alter/U004__migrate_ids_to_uuid.sql.
-- The uuid -> bigint reversal is not symmetric; dev rebuild requires
-- dropping the schema and re-applying V001..V004.
--
-- Risk: any non-seeded rows in idempotency_key lose the numeric
-- correspondence with patients.id. In this corte there is no production
-- data, so this is acceptable. Documented in the PR.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. patients.id: BIGSERIAL -> uuid
-- ---------------------------------------------------------------------
ALTER TABLE patients
    ALTER COLUMN id DROP DEFAULT;

ALTER TABLE patients
    ALTER COLUMN id TYPE uuid USING gen_random_uuid();

ALTER TABLE patients
    ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- ---------------------------------------------------------------------
-- 2. patients.user_id: BIGINT -> uuid (deterministic for seeded rows)
-- ---------------------------------------------------------------------
ALTER TABLE patients
    ALTER COLUMN user_id TYPE uuid
    USING (
        CASE user_id
            WHEN 1001 THEN '00000000-0000-0000-0000-000000001001'::uuid
            WHEN 1002 THEN '00000000-0000-0000-0000-000000001002'::uuid
            ELSE gen_random_uuid()
        END
    );

-- ---------------------------------------------------------------------
-- 3. idempotency_key.user_id: BIGINT -> uuid
-- ---------------------------------------------------------------------
ALTER TABLE idempotency_key
    ALTER COLUMN user_id TYPE uuid
    USING (
        CASE user_id
            WHEN 1001 THEN '00000000-0000-0000-0000-000000001001'::uuid
            WHEN 1002 THEN '00000000-0000-0000-0000-000000001002'::uuid
            ELSE gen_random_uuid()
        END
    );

-- ---------------------------------------------------------------------
-- 4. idempotency_key.resource_id: BIGINT -> uuid
--    No seed exists; any previous numeric value is replaced by a random
--    UUID. In this corte there is no production data.
-- ---------------------------------------------------------------------
ALTER TABLE idempotency_key
    ALTER COLUMN resource_id TYPE uuid USING gen_random_uuid();

-- ---------------------------------------------------------------------
-- 5. Comments (update to reflect the new type)
-- ---------------------------------------------------------------------
COMMENT ON COLUMN patients.id
    IS 'Internal primary key of the patient record (UUID).';

COMMENT ON COLUMN patients.user_id
    IS 'External reference to auth-service user id (JWT sub). UUID. Unique among active records.';

COMMENT ON COLUMN idempotency_key.user_id
    IS 'External reference to auth-service user id (JWT sub). UUID.';

COMMENT ON COLUMN idempotency_key.resource_id
    IS 'Reference to the created resource (patients.id). UUID.';
