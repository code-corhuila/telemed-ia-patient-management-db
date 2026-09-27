# telemed-ia-patient-management-db

> **patient-management bounded context:** database, schema, seeds and migrations.

Part of the **TeleMed IA** distributed system — team `telemed-ia`, Grupo 2.

Governance and documentation live in [`telemed-ia-docs`](https://github.com/code-corhuila/telemed-ia-docs).

---

## Purpose

This repository owns the persistent database schema for the **`patient-management` bounded context**.

It is the **single source of truth** for everything related to the patient database:

* The `patients` table and patient profile data.
* Future `medical_history_entries`, if structured medical history is introduced after MVP.
* Database extensions, schemas, types and database objects.
* Indexes and constraints.
* Seed data.
* Flyway migrations.
* Database roles and permissions.
* Manual rollback scripts.

Any schema change must go through a **new Flyway migration** and a Pull Request against the appropriate branch.

---

## Repository structure

```text
.
├── 01_ddl/                    DDL — definition
│   ├── 00_extensions/         PostgreSQL extensions
│   ├── 01_schemas/            Database schemas
│   ├── 02_types/              Custom types and enums
│   ├── 03_tables/             Table definitions
│   ├── 04_alter/              Foreign keys and later alterations
│   ├── 05_views/              Views
│   ├── 06_materialized_views/ Materialized views
│   ├── 07_functions/          Functions
│   ├── 08_procedures/         Procedures
│   ├── 09_triggers/           Triggers
│   └── 10_indexes/            Indexes
│
├── 02_dml/                    DML — data manipulation
│   ├── 00_inserts/            Seed data
│   ├── 01_updates/            Data updates
│   ├── 02_deletes/            Data deletes
│   ├── 03_upserts/            Upserts
│   └── 04_patches/            Idempotent data patches
│
├── 03_dcl/                    DCL — access control
│   ├── 00_roles/              Roles
│   ├── 01_grants/             Grants
│   └── 02_policies/           Row-level policies
│
├── 04_tcl/                    TCL — transaction control
│   ├── 00_transaction_blocks/ Transactional blocks
│   ├── 01_manual_recoveries/  Manual recovery scripts
│   └── 02_release_tags/       Release tags
│
├── 05_rollbacks/              Reversal scripts, mirror of the above
│   ├── 01_ddl/
│   ├── 02_dml/
│   └── 03_dcl/
│
├── deploy/
│   └── compose.yml            PostgreSQL 16 + Flyway migration runner
│
├── .github/
│   └── workflows/
│       └── db-ci.yml          Reconstruction verification
│
├── flyway.toml                Flyway configuration
├── .env.example               Example environment variables
├── CONTRIBUTING.md            Contribution and migration rules
└── README.md
```

---

## Stack

| Component               | Version |
| ----------------------- | ------- |
| PostgreSQL              | 16      |
| Flyway                  | 10.x    |
| Docker / Docker Compose | Latest  |

### Migration tool

This repository uses **Flyway** as its database migration tool.

The use of Flyway is registered and governed by the architecture decisions documented in `telemed-ia-docs`.

---

## Branching

Three permanent branches are used. **None of them accepts a direct commit** — development enters through a child branch and leaves through a Pull Request.

```text
develop  <--PR--  feat/... fix/... chore/...
qa       <--PR--  promote/...
main     <--PR--  release/...  hotfix/...
```

Promotion happens **by re-application** using:

```bash
git cherry-pick -x
```

Permanent branches are never promoted by merging one permanent branch into another.

### Main branch

`main` requires **1 approval from `@ariel5253`**.

On `develop` and `qa`, the team defines its own review rule.

Full branching policy:

`telemed-ia-docs/00-governance/branching-policy.md`

---

## Database ownership

This repository is the authoritative owner of:

* The `patients` table structure.
* Patient-context database objects.
* Indexes, constraints and seed data.
* Database roles and permissions.
* Migrations and rollback scripts for this bounded context.

It does **not** own:

* User authentication tables, owned by `telemed-ia-identity-and-access-db`.
* Professional profile tables, owned by `telemed-ia-professional-management-db`.

Cross-service references use **external identifiers** and do not create foreign keys to another service's database.

---

## Local development

### Prerequisites

Install:

* Docker Desktop or Docker Engine.
* Git.

---

## Environment variables

Copy the example environment file:

```bash
cp .env.example .env
```

Then configure the required database credentials.

**Never commit real credentials to the repository.**

Only `.env.example` should be versioned.

---

## Start the database

### 1. Create the shared Docker network

If the shared `platform` network does not already exist:

```bash
docker network create platform
```

This only needs to be done once per machine.

### 2. Start PostgreSQL

```bash
docker compose -f deploy/compose.yml --env-file .env up -d
```

### 3. Apply Flyway migrations

```bash
docker compose -f deploy/compose.yml --env-file .env \
  --profile tooling run --rm patients-db-migrate
```

Flyway applies all migrations that have not yet been executed.

---

## Verify the database

Connect to PostgreSQL:

```bash
docker compose -f deploy/compose.yml --env-file .env \
  exec patients-db psql -U telemed_patient_user -d telemed_patient_db
```

Inside `psql`:

```sql
\dt              -- list tables
\d patients      -- describe the patients table
SELECT * FROM patients;
\q               -- exit
```

---

## Stop the database

```bash
docker compose -f deploy/compose.yml --env-file .env down
```

To also remove the PostgreSQL volume:

```bash
docker compose -f deploy/compose.yml --env-file .env down -v
```

> **Warning:** removing the volume is destructive and deletes the local database data.

---

## Flyway operations

### Apply pending migrations

```bash
docker compose -f deploy/compose.yml --env-file .env \
  --profile tooling run --rm patients-db-migrate
```

### Check migration status

```bash
docker compose -f deploy/compose.yml --env-file .env \
  --profile tooling run --rm patients-db-migrate \
  -configFiles=flyway.toml info
```

### Validate migrations

```bash
docker compose -f deploy/compose.yml --env-file .env \
  --profile tooling run --rm patients-db-migrate \
  -configFiles=flyway.toml validate
```

Validation verifies that applied migrations have not been modified.

### Manual rollback

Rollback scripts from `05_rollbacks/` are executed manually with `psql` according to the recovery procedure.

Rollback scripts are **not executed automatically by Flyway**.

When multiple migrations must be reverted, execute the rollback scripts from the highest version to the lowest.

For example:

```text
U5__...
U4__...
U3__...
U2__...
```

---

## Migration conventions

Flyway migrations use the following naming convention:

```text
V<n>__<description>.sql
```

Migration numbers must not contain leading zeros.

Examples:

```text
V1__initial_schema.sql
V2__seed_patients.sql
V3__add_patient_status.sql
```

Applied migrations are **never edited**.

If an already-applied migration needs to be corrected, create a new migration instead.

For example:

```text
V3__add_patient_status.sql
V4__fix_patient_status.sql
```

### Idempotent seed data

Seed data must be idempotent.

For example:

```sql
INSERT INTO patients (
    user_id,
    birth_date,
    phone,
    medical_history,
    description
)
VALUES
    (
        1001,
        '1990-05-15',
        '3001234567',
        'Hypertension, controlled with medication.',
        'No known allergies.'
    ),
    (
        1002,
        '1985-11-03',
        '3007654321',
        'Type 2 diabetes, diagnosed in 2018.',
        'Allergic to penicillin.'
    )
ON CONFLICT DO NOTHING;
```

This prevents duplicate seed records when the same seed operation encounters an existing conflicting record.

---

## Rollbacks

Every migration must have a corresponding rollback script in `05_rollbacks/`.

Example:

```text
V1__initial_schema.sql
        ↓
U1__initial_schema.sql

V2__seed_patients.sql
        ↓
U2__seed_patients.sql
```

Rollback scripts must:

* Use the same migration number.
* Use the `U` prefix.
* Be stored under `05_rollbacks/`.
* Not be included in Flyway migration locations.
* Be executed manually when a rollback or recovery is explicitly required.

The rollback should remove only the objects or data introduced by its corresponding migration.

---

## CI

The workflow `.github/workflows/db-ci.yml` validates the complete migration lifecycle:

1. Creates a PostgreSQL database from an empty state.
2. Applies all Flyway migrations.
3. Executes the corresponding `U<n>__...sql` rollback scripts.
4. Verifies that the schema has been reverted to an empty state.
5. Applies all migrations again.
6. Validates that the database can be reconstructed successfully.

---

## Repository rules

The following rules are mandatory:

* The database schema for this bounded context lives **only in this repository**.
* An applied migration is **never edited**.
* Schema corrections require a **new migration**.
* Every migration must have a corresponding rollback script in `05_rollbacks/`.
* Rollback scripts are not part of Flyway's migration locations.
* Seed data must be idempotent.
* Real credentials must never be committed.
* Only `.env.example` may contain example credentials.
* Cross-service database relationships must use external identifiers instead of foreign keys to another service's database.
* Database changes must go through a Pull Request.
* Direct commits to `develop`, `qa`, and `main` are not allowed.
* Promotion between permanent branches must use `git cherry-pick -x`.
* Migration numbers must not contain leading zeros.
* A migration that has already been applied must never be modified.

---

## Related documentation

* `telemed-ia-docs/00-governance/branching-policy.md`
* `telemed-ia-docs/05-architecture/decisions/records/ADR-004-database-per-service.md`
* `telemed-ia-docs/06-data/models.md`
* `telemed-ia-docs/09-microservices/services/03-patient-service/data-model.md`
* `CONTRIBUTING.md`
