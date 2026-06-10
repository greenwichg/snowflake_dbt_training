# Exercise 1 — Install dbt and connect it to Snowflake

## 1. Install dbt

```bash
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install dbt-snowflake
dbt --version
```

## 2. Configure the connection

dbt reads credentials from `~/.dbt/profiles.yml` (kept **outside** the repo so secrets are never committed).

```bash
mkdir -p ~/.dbt
cp dbt_training/profiles.yml.example ~/.dbt/profiles.yml
```

Edit `~/.dbt/profiles.yml`:

- `account`: your account identifier — in Snowsight, click your name → Account → copy the identifier (format `orgname-accountname`).
- `user` / `password`: your trial login.
- `role`: `TRANSFORMER` (created on Day 2, Exercise 4 — use `SYSADMIN` if you skipped it).
- `schema`: `DBT_<YOURNAME>` — your personal dev schema; dbt creates it on first run.

## 3. Verify

```bash
cd dbt_training
dbt debug          # all checks should be green
dbt deps           # install packages (used on Day 4)
dbt run            # build everything
dbt ls             # list all resources in the project
```

`dbt run` should report staging views and mart tables built into `TRAINING_DB.DBT_<YOURNAME>`. Find them in Snowsight, and look at a query it ran in Query History — dbt is "just" templated SQL executed in your warehouse.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `250001: Could not connect` | Check `account` identifier format (`orgname-accountname`, no `.snowflakecomputing.com`). |
| `Object 'TRAINING_DB.RAW.CUSTOMERS' does not exist` | Day 1 exercises not completed, or role can't see RAW — re-run Day 2 grants. |
| `Insufficient privileges to operate on database` | Use role `TRANSFORMER` with the Day 2 grants, or fall back to `SYSADMIN`. |
