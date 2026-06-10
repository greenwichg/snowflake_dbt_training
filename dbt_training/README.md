# dbt_training — the working dbt project (Days 3–6)

Transforms the raw data loaded in the Day 1 Snowflake labs into analytics-ready models.

## DAG

```
source: raw.customers ──→ stg_customers ──→ int_customer_orders ──→ dim_customers
source: raw.orders ─────→ stg_orders ────↗︎                    ↘──→ fct_orders
source: raw.web_events_raw → stg_web_events ──────────────────────→ fct_web_events (incremental)
seed:   fx_rates ─────────↗ (used by stg_orders via convert_to_usd macro)
snapshot: customers_snapshot (SCD2 over raw.customers)
```

## Layout

| Path | What | Introduced |
|---|---|---|
| `models/staging/` | Source declarations + 1:1 cleaned views over raw (view) | Day 3 |
| `models/intermediate/` | Reusable logic steps (ephemeral — inlined as CTEs) | Day 3–4 |
| `models/marts/` | Business-ready `dim_`/`fct_` (table / incremental) | Day 3 |
| `seeds/fx_rates.csv` | Small static lookup loaded with `dbt seed` | Day 3 |
| `snapshots/customers_snapshot.sql` | SCD Type 2 history | Day 3 |
| `macros/convert_to_usd.sql` | Reusable Jinja macro | Day 4 |
| `tests/` | Singular data tests | Day 4 |
| `tests/generic/test_is_positive.sql` | Custom generic (schema) test | Day 4 |
| `packages.yml` | `dbt_utils` + `dbt_expectations` | Day 4 |
| `models/marts/_marts.yml` | Docs, tests, and an enforced data contract on `dim_customers` | Day 4 |
| `dbt_project.yml` | Commented `+schema: silver/gold` Medallion wiring | Day 5 |

## Commands

```bash
dbt debug                 # check connection
dbt deps                  # install packages (dbt_utils)
dbt seed                  # load seeds (fx_rates)
dbt run                   # build all models
dbt test                  # run all tests
dbt build                 # seed + run + test + snapshot, DAG-ordered
dbt snapshot              # capture SCD2 history
dbt docs generate && dbt docs serve   # browse docs + lineage graph
```

Connection setup: see [`../day3_dbt_fundamentals/01_setup_dbt_snowflake.md`](../day3_dbt_fundamentals/01_setup_dbt_snowflake.md).
