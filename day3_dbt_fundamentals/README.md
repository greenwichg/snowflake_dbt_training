# Day 3 — dbt Fundamentals

> From here on we work inside the [`dbt_training/`](../dbt_training/) project at the repo root.

## Topics Covered

- What dbt is and where it sits in ELT (the **T**, running inside Snowflake)
- dbt project anatomy: `dbt_project.yml`, models, `profiles.yml`
- **Sources** (`source()`): declaring raw tables dbt reads but doesn't build
- **Models** & **`ref()`**: SQL `SELECT`s that dbt materializes, with automatic dependency ordering (the DAG)
- **Materializations**: `view`, `table` (`incremental` and snapshots come on Day 4)
- Staging vs marts layering convention
- Jinja basics: `{{ }}`, `{% %}`, simple loops
- `dbt run`, `dbt compile`, `dbt run -s <model>`, the `target/` folder

## Hands-On Practice

1. **Install & connect** — follow [`01_setup_dbt_snowflake.md`](01_setup_dbt_snowflake.md): install `dbt-snowflake`, configure `profiles.yml` from [`../dbt_training/profiles.yml.example`](../dbt_training/profiles.yml.example), then `dbt debug`.
2. **Declare sources** — read [`models/staging/_sources.yml`](../dbt_training/models/staging/_sources.yml); run `dbt source freshness`.
3. **Run the staging models** — `dbt run -s staging`. Inspect compiled SQL in `target/compiled/`. Find the views in Snowsight (`<your_dev_schema>` in `TRAINING_DB`).
4. **Run the marts** — `dbt run -s marts`. Look at `fct_orders` and `dim_customers`; trace the DAG with `dbt ls -s +fct_orders`.
5. **Build your own model** — create `models/marts/fct_monthly_revenue.sql` that aggregates `ref('fct_orders')` by month (you wrote this SQL on Day 1, Exercise 6!). Run just it: `dbt run -s fct_monthly_revenue`.

## Learning Outcomes

- Set up dbt against Snowflake and explain the project structure
- Write models that build on sources and other models via `ref()` / `source()`
- Choose between view and table materializations
- Read compiled SQL and the dbt DAG
