# Contributing

> Short guide for contributing to this repository.

---

## Branch model

This repository uses three persistent branches:

- `develop` — main development branch. All new work is merged here first.
- `qa` — QA and validation branch. Receives changes promoted from `develop`.
- `main` — stable branch. Receives changes promoted from `qa` after validation.

**Direct commits to `develop`, `qa`, or `main` are not allowed.**

---

## Workflow

### 1. Develop

```bash
git switch develop
git pull origin develop
git switch -c chore/<short-description>
```

Make changes, then:

```bash
git add .
git commit -m "chore(db): <short description>"
git push -u origin chore/<short-description>
```

Open a Pull Request against `develop`. Wait for CI to pass and for 2 approvals, then merge.

### 2. Promote to `qa`

```bash
git switch qa
git pull origin qa
git switch -c qa/<short-description>
git cherry-pick -x <sha-of-the-commit-in-develop>
git push -u origin qa/<short-description>
```

Open a Pull Request against `qa`. Wait for CI and approvals, then merge.

### 3. Promote to `main`

```bash
git switch main
git pull origin main
git switch -c release/<version>
git cherry-pick -x <sha-of-the-commit-in-qa>
git push -u origin release/<version>
```

Open a Pull Request against `main`. Requires approval from `@ariel5253`.

> **The `-x` flag in `cherry-pick` is mandatory.** It preserves the traceability of the original
> commit and lets reviewers verify which changes came from where. Without it, the promotion trail
> is lost.

---

## Commit convention

Use Conventional Commits:

```text
<type>(<scope>): <short description>
```

Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `perf`.

For this repository, use the scope `db`:

```text
chore(db): add patients table
feat(db): add medical_history_entries table
fix(db): correct phone column length
```

---

## Migration rules

- Migrations are **forward-only**.
- **Never modify** a migration that has already been applied in any environment.
- **One logical change per migration.**
- Use descriptive, snake_case names: `V3__add_patient_preferred_language.sql`.
- Test migrations against a copy of the target environment's data before deploying.
- Migrations use `IF NOT EXISTS` where applicable for idempotency.

---

## Pull request checklist

Before opening a PR:

- [ ] CI passes locally (`mvn --batch-mode clean verify`).
- [ ] Migrations apply cleanly (`docker compose up -d`).
- [ ] No secrets committed (only `.env.example`).
- [ ] Documentation affected by the change is updated.
- [ ] Branch follows the naming convention.