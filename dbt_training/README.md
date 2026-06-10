# dbt_training — the working dbt project (Days 3–6)

Transforms the raw data loaded in the Day 1 Snowflake labs into analytics-ready models.

## DAG

```
source: raw.customers ──→ stg_customers ──┬─→ dim_customers
source: raw.orders ─────→ stg_orders ─────┴─→ fct_orders
source: raw.web_events_raw → stg_web_events ─→ fct_web_events (incremental)
seed:   fx_rates ─────────↗ (used by stg_orders via convert_to_usd macro)
snapshot: customers_snapshot (SCD2 over raw.customers)
```

## Layout

| Path | What | Introduced |
|---|---|---|
| `models/staging/` | Source declarations + 1:1 cleaned views over raw | Day 3 |
| `models/marts/` | Business-ready tables (`dim_`, `fct_`) | Day 3 |
| `models/marts/fct_web_events.sql` | Incremental materialization | Day 4 |
| `seeds/fx_rates.csv` | Small static lookup loaded with `dbt seed` | Day 4 |
| `macros/convert_to_usd.sql` | Reusable Jinja macro | Day 4 |
| `snapshots/customers_snapshot.sql` | SCD Type 2 history | Day 4 |
| `tests/` | Singular data tests | Day 4 |

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
