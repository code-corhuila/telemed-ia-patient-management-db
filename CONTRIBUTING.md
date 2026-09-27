# Contributing

> Short guide for contributing to this repository.

---

## Branch model

This repository uses three persistent branches:

* `develop` — main development branch. All new work is merged here first.
* `qa` — QA and validation branch. Receives changes promoted from `develop`.
* `main` — stable branch. Receives changes promoted from `qa` after validation.

**Direct commits to `develop`, `qa`, or `main` are not allowed.**

All changes must enter through a child branch and a Pull Request.

The promotion model is based on **re-application with `git cherry-pick -x`**, not on merging one persistent branch into another.

The following merges are not used:

```text
merge develop -> qa
merge qa -> main
```

---

## Workflow

> **Review rule:** the team requires **1 approval** for Pull Requests targeting
> `develop` and `qa`. This rule is also registered in
> `telemed-ia-docs/00-governance/git-conventions.md`, per normative numeral 9.4.

> Pull Requests targeting `main` require **1 approval from `@ariel5253`**,
> as defined by `CODEOWNERS`.

### 1. Develop

Start from the latest `develop` branch:

```bash
git switch develop
git pull origin develop
git switch -c chore/<short-description>
```

Make your changes, then:

```bash
git add .
git commit -m "chore(db): <short description>"
git push -u origin chore/<short-description>
```

Open a Pull Request against `develop`.

The PR must:

1. Pass CI.
2. Have the required review.
3. Satisfy the Pull Request checklist.
4. Be merged only after the required approval is obtained.

---

### 2. Promote to `qa`

Promotion to `qa` is performed by re-applying the commit from `develop`.

> **Important:** the branch prefix cannot be `qa/` because Git does not allow a
> branch and a directory with the same name to coexist. The prefix `promote/` is
> used instead.

```bash
git switch qa
git pull origin qa
git switch -c promote/<short-description>
git cherry-pick -x <sha-of-the-commit-in-develop>
git push -u origin promote/<short-description>
```

Open a Pull Request against `qa`.

The PR must pass CI and obtain the required approval before being merged.

---

### 3. Promote to `main`

Promotion to `main` is performed by re-applying the commit from `qa`.

```bash
git switch main
git pull origin main
git switch -c release/<version>
git cherry-pick -x <sha-of-the-commit-in-qa>
git push -u origin release/<version>
```

Open a Pull Request against `main`.

The PR requires approval from:

```text
@ariel5253
```

### Cherry-pick traceability

The `-x` flag in `git cherry-pick` is **mandatory**.

It preserves the reference to the original commit and allows reviewers to trace how a change moved through:

```text
develop -> qa -> main
```

Do not promote changes using a normal `cherry-pick` without `-x`.

---

## Branch naming

Use descriptive branch names according to the type of work.

Examples:

```text
feat/add-patient-status
fix/patient-index
chore/update-flyway
chore/update-database-docs
chore/migration-validation
promote/patient-status
release/v1.2.0
hotfix/patient-schema
```

Recommended prefixes:

* `feat/` — new functionality or database capability.
* `fix/` — bug or database correction.
* `chore/` — maintenance, configuration, documentation or tests.
* `promote/` — promotion to QA.
* `release/` — promotion to production.
* `hotfix/` — urgent production correction.

---

## Commit convention

Use **Conventional Commits**:

```text
<type>(<scope>): <short description>
```

Allowed types:

* `feat`
* `fix`
* `docs`
* `chore`
* `refactor`
* `test`
* `perf`

For this repository, use the `db` scope:

```text
chore(db): add patients table
feat(db): add medical_history_entries table
fix(db): correct phone column length
docs(db): update migration documentation
test(db): validate patient migration
```

Keep commit messages short, descriptive and written in the imperative form.

---

## Database migrations

This repository uses **Flyway** for database schema migrations.

Migrations are stored according to the repository's database organization and are executed in version order.

### Migration naming

Every Flyway migration must follow:

```text
V<n>__<description>.sql
```

The migration number must not contain leading zeros.

Examples:

```text
V1__initial_schema.sql
V2__add_patient_status.sql
V3__add_patient_preferred_language.sql
```

Use descriptive `snake_case` names.

---

## Migration rules

### Forward-only

Migrations are **forward-only**.

Once a migration has been applied to an environment, **never modify it**.

If a correction is required, create a new migration:

```text
V4__fix_patient_preferred_language.sql
```

Changing an applied migration changes its Flyway checksum and can cause migration validation failures or inconsistencies between environments.

---

### One logical change per migration

Each migration should contain **one logical database change**.

Avoid combining unrelated schema changes into a single migration.

For example, prefer:

```text
V4__add_patient_status.sql
V5__add_patient_indexes.sql
```

over:

```text
V4__change_everything.sql
```

---

### Idempotency

Use `IF NOT EXISTS` or equivalent safeguards where appropriate.

Examples:

```sql
CREATE TABLE IF NOT EXISTS ...;
CREATE INDEX IF NOT EXISTS ...;
```

For seed data, use conflict handling such as:

```sql
ON CONFLICT (...) DO NOTHING
```

or:

```sql
ON CONFLICT (...) DO UPDATE
```

according to the intended behavior.

Do not add idempotency blindly if it could hide a real database inconsistency.

---

## Seed data

Seed data belongs in:

```text
02_dml/00_inserts/
```

Seed operations must be designed to be idempotent whenever possible:

```sql
INSERT INTO patient_status (code, name)
VALUES ('ACTIVE', 'Active')
ON CONFLICT (code) DO NOTHING;
```

Seed data must not create duplicate records when the deployment process is repeated.

---

## Rollbacks

Every Flyway migration must have a corresponding manual rollback script.

For example:

```text
V3__add_patient_preferred_language.sql
```

must have:

```text
05_rollbacks/01_ddl/03_tables/U3__add_patient_preferred_language.sql
```

The rollback uses:

* The same migration number.
* The `U` prefix.
* A descriptive name corresponding to the migration.

### Rollback rules

Rollback scripts:

* Live exclusively in `05_rollbacks/`.
* Are **not executed automatically by Flyway**.
* Must not be included in Flyway's configured migration `locations`.
* Are executed manually only when a recovery or rollback has been explicitly authorized.

When reverting multiple migrations, execute them from the highest version to the lowest:

```text
U5__...
U4__...
U3__...
```

---

## DDL, DML, DCL and TCL organization

Database changes must respect the repository's directory organization:

```text
01_ddl/         DDL — definition
02_dml/         DML — data manipulation
03_dcl/         DCL — access control
04_tcl/         TCL — transaction control
05_rollbacks/   reversal scripts
```

### `01_ddl/`

Extensions, schemas, types, tables, constraints, views, functions, triggers and indexes.

### `02_dml/`

Seed data, data patches and idempotent data corrections.

### `03_dcl/`

Roles, grants and permissions.

### `04_tcl/`

Transactional blocks, manual recovery scripts and release tags.

### `05_rollbacks/`

Manual `U<n>__...sql` rollback scripts.

---

## Production database safety

Never introduce destructive schema changes without verifying their impact on production.

Avoid:

```sql
DROP TABLE
DROP COLUMN
```

when application code may still depend on the affected object.

Use a two-phase deprecation approach:

1. Remove application dependencies on the object.
2. Remove the database object in a later migration.

---

## Testing migrations

Before opening a Pull Request, verify that:

1. The database can be created from an empty state.
2. All migrations apply successfully.
3. Flyway validation succeeds.
4. Seed data is inserted correctly.
5. The schema matches the expected structure.
6. Rollback scripts execute correctly where applicable.
7. The migrations can be applied again after a complete rollback.

Useful commands:

```bash
# Start the database
docker compose -f deploy/compose.yml --env-file .env up -d

# Apply migrations
docker compose -f deploy/compose.yml --env-file .env \
  --profile tooling run --rm patients-db-migrate

# Check migration status
docker compose -f deploy/compose.yml --env-file .env \
  --profile tooling run --rm patients-db-migrate \
  -configFiles=flyway.toml info

# Validate migrations
docker compose -f deploy/compose.yml --env-file .env \
  --profile tooling run --rm patients-db-migrate \
  -configFiles=flyway.toml validate
```

---

## CI

The database CI workflow is located at:

```text
.github/workflows/db-ci.yml
```

The CI process verifies the migration lifecycle by:

1. Creating the database from an empty state.
2. Applying all Flyway migrations.
3. Executing the rollback scripts.
4. Verifying that the schema was reverted.
5. Applying the migrations again.
6. Validating the resulting database.

A Pull Request must not be merged when the required CI checks are failing.

---

## Secrets and environment variables

Never commit real credentials, passwords, tokens or other secrets.

The repository may contain `.env.example` with example values.

Local credentials belong in `.env`, which must not be committed.

Before opening a Pull Request, verify that no credentials or secrets were accidentally added:

```bash
git status
git diff --cached
```

---

## Pull Request guidelines

A Pull Request should:

* Have a clear title.
* Explain what database change is being introduced.
* Explain any migration or data impact.
* Mention relevant documentation changes.
* Include testing performed locally.
* Keep unrelated changes out of the PR.
* Pass the required CI checks.
* Obtain the required approval.

For database changes, reviewers should pay particular attention to:

* Migration ordering.
* Migration naming.
* Schema compatibility.
* Existing data.
* Constraints and indexes.
* Seed idempotency.
* Rollback availability.
* Production impact.
* Cross-service database boundaries.

---

## Pull Request checklist

Before opening a PR:

* [ ] Branch is based on the correct persistent branch.
* [ ] Branch follows the naming convention.
* [ ] No direct commit was made to `develop`, `qa`, or `main`.
* [ ] Commit messages follow Conventional Commits.
* [ ] Migration names follow `V<n>__<snake_case_description>.sql`.
* [ ] Applied migrations were not modified.
* [ ] Every new migration has a corresponding `U<n>__...sql` rollback.
* [ ] Rollback scripts are located in `05_rollbacks/`.
* [ ] Seed data is located in `02_dml/00_inserts/`.
* [ ] Seed data is idempotent.
* [ ] No real credentials or secrets were committed.
* [ ] Documentation affected by the change is updated.
* [ ] Migrations apply cleanly from an empty database.
* [ ] Flyway validation passes.
* [ ] Rollback procedures have been tested where applicable.
* [ ] Docker-based database checks pass.
* [ ] CI passes.
* [ ] The required reviewer has been requested.

---

## Promotion checklist

### `develop` → `qa`

* [ ] Change has already been merged into `develop`.
* [ ] Correct commit SHA from `develop` was selected.
* [ ] `git cherry-pick -x` was used.
* [ ] Promotion branch is named `promote/<description>`.
* [ ] PR targets `qa`.
* [ ] CI passes.
* [ ] Required approval is obtained.

### `qa` → `main`

* [ ] Change has already been validated in `qa`.
* [ ] Correct commit SHA from `qa` was selected.
* [ ] `git cherry-pick -x` was used.
* [ ] Promotion branch is named `release/<version>`.
* [ ] PR targets `main`.
* [ ] CI passes.
* [ ] `@ariel5253` approval is obtained.

---

## Related documentation

For repository governance and architecture, see:

* `telemed-ia-docs/00-governance/branching-policy.md`
* `telemed-ia-docs/00-governance/git-conventions.md`
* `telemed-ia-docs/05-architecture/decisions/records/ADR-004-database-per-service.md`
* `telemed-ia-docs/06-data/models.md`
* `telemed-ia-docs/09-microservices/services/03-patient-service/data-model.md`

For the database itself, see:

* `README.md`
* `flyway.toml`
* `deploy/compose.yml`
* `.github/workflows/db-ci.yml`
