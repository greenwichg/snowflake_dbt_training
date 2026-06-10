# Day 4 — DBT Transformations, Testing & Documentation

> 🧠 **New to these topics?** Read [CONCEPTS.md](CONCEPTS.md) first — every concept below explained from zero, with analogies.

> All exercises happen in [`dbt_training/`](../dbt_training/); each feature below is already wired into the project so you can study a working example, then extend it.

## Topics Covered

- **Jinja Macros & Reusable Logic** — DRY SQL; see [`macros/convert_to_usd.sql`](../dbt_training/macros/convert_to_usd.sql) used by `stg_orders`
- **Staging → Intermediate → Marts Layer Design** — staging cleans 1:1 per source; intermediate holds reusable business steps (often ephemeral); marts are the consumable `dim_`/`fct_` tables. See `stg_orders` → [`int_customer_orders`](../dbt_training/models/intermediate/int_customer_orders.sql) → `dim_customers`
- **DBT Tests — Generic & Singular** — generic = parameterized, declared in YAML (`unique`, `not_null`, `accepted_values`, `relationships`); singular = a one-off SQL file in `tests/` that must return zero rows
- **Custom Schema Tests** — write your own generic test in `tests/generic/`; see [`test_is_positive.sql`](../dbt_training/tests/generic/test_is_positive.sql), applied to `fct_orders.amount_usd`
- **dbt-expectations Package** — Great-Expectations-style assertion library; see the email regex test on `stg_customers`
- **DBT Docs Generation** — YAML descriptions become a browsable docs site
- **Lineage Graphs & Data Contracts** — the DAG view in dbt docs; contracts pin a model's exact schema (see `dim_customers` in [`_marts.yml`](../dbt_training/models/marts/_marts.yml))

## Hands-On Practice

| # | Exercise |
|---|---|
| 19 | **Write Jinja macros for reusable SQL logic** — study `convert_to_usd`; then write your own `pct(numerator, denominator)` macro that emits a safe `round(100 * n / nullif(d, 0), 1)` and use it in a model |
| 20 | **Build staging + intermediate + marts layers** — trace `stg_orders` → `int_customer_orders` → `dim_customers` (`dbt ls -s +dim_customers`); add your own `int_customer_web_activity` (events per customer from `stg_web_events`) and join it into `dim_customers` |
| 21 | **Add not_null, unique, accepted_values, relationships tests** — all four are live in [`_staging.yml`](../dbt_training/models/staging/_staging.yml) / [`_marts.yml`](../dbt_training/models/marts/_marts.yml); add `accepted_values` for `stg_web_events.device` |
| 22 | **Write a custom singular test** — study [`assert_no_negative_completed_revenue.sql`](../dbt_training/tests/assert_no_negative_completed_revenue.sql); write *no order may predate its customer's signup date* |
| 23 | **Run dbt test and interpret failures** — `dbt test`; then break one on purpose: insert a duplicate `ORDER_ID` into `RAW.ORDERS`, run `dbt test -s stg_orders`, open the compiled test SQL from `target/` to find the offending rows, fix, re-run. Try `dbt build` to see tests gate downstream models |
| 24 | **Generate and serve dbt docs site** — `dbt docs generate && dbt docs serve`; explore model pages, column descriptions, and the lineage graph from `raw` sources to marts; click through `dim_customers`' enforced contract |

> ✅ **Stuck or done?** Reference answers for the write-it-yourself tasks are in [solutions/](solutions/).

## Learning Outcomes

- ✅ Build layered transformations (staging → marts)
- ✅ Implement reusable logic using macros
- ✅ Add data quality checks at multiple levels
- ✅ Generate a full DBT documentation site with lineage
