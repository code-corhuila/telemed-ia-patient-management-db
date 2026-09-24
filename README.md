# telemed-ia-patient-management-db

> patient-management bounded context: database (schema, seeds, migrations)

Part of the **TeleMed IA** distributed system — team `telemed-ia`, Grupo 2.
Governance and documentation live in [`telemed-ia-docs`](https://github.com/code-corhuila/telemed-ia-docs).

## Branching

Three permanent branches. **None of them accepts a direct commit** — you enter through a child
branch and leave through a Pull Request.

```
develop  <--PR--  feat/... fix/... chore/...
qa       <--PR--  qa/...
main     <--PR--  release/...  hotfix/...
```

Promotion happens **by re-application** (`git cherry-pick -x`), never by merging one permanent
branch into another: `merge develop -> qa` and `merge qa -> main` do not exist in this model.

`main` requires **1 approval from `ariel5253`**. On `develop` and `qa` the team sets its own review
rule.

Full policy: `00-governance/branching-policy.md` in `telemed-ia-docs`.

## Purpose

Own the persistent schema for the `patient-service` bounded context:

- The `patients` table (patient profile).
- Future: `medical_history_entries` (if structured history is introduced post-MVP).

This repository is the **single source of truth** for the patient database schema. Any schema
change must go through a new Flyway migration and a Pull Request against the appropriate branch.

## Stack

| Component | Version |
|-----------|---------|
| PostgreSQL | 16 |
| Flyway | 10.x |
| Java (for running migrations via Maven) | 17 |
| Docker / Docker Compose | latest |

## Local development

### Prerequisites

- Docker Desktop or Docker Engine
- Java 17 (for running Flyway via Maven)
- Git

### Start the database

```bash
docker compose up -d
```

This starts:

- A PostgreSQL 16 instance on port `5432`.
- A Flyway container that applies all pending migrations on startup.

### Verify the schema

```bash
# Connect to the database
docker compose exec postgres psql -U telemed_patient_user -d telemed_patient_db

# Inside psql:
\dt                    -- list tables
\d patients            -- describe the patients table
SELECT * FROM patients; -- view seed data
\q                     -- exit
```

### Stop the database

```bash
docker compose down
```

To also remove the volume (destructive):

```bash
docker compose down -v
```

## Running migrations manually

If you prefer running Flyway outside Docker:

```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=telemed_patient_db
export DB_USER=telemed_patient_user
export DB_PASSWORD=telemed_patient_password

mvn flyway:migrate
mvn flyway:info
```

## Migration rules

- **Forward-only.** Migrations are never modified after they are merged.
- **One logical change per migration.**
- **Naming convention:** `V{N}__{snake_case_description}.sql`
- **Seed data** goes in separate migrations with the `V{N}__` prefix.
- **Never** use `DROP COLUMN` or `DROP TABLE` if code in production depends on it. Follow the
  two-phase deprecation pattern.

## Ownership

This repository is the authoritative owner of:

- The `patients` table structure.
- Any indexes, constraints, and seed data for the patient context.

It does **not** own:

- User authentication tables (owned by `telemed-ia-identity-and-access-db`).
- Appointment tables (owned by `telemed-ia-appointment-scheduling-db`).
- Clinical content (owned by `telemed-ia-medical-consultation-db`).

Cross-service references are done through external identifiers, never through foreign keys to
another service's database.

## Related documentation

- `telemed-ia-docs/06-data/models.md`
- `telemed-ia-docs/09-microservices/services/03-patient-service/data-model.md`
- `telemed-ia-docs/05-architecture/decisions/records/ADR-004-database-per-service.md`

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).