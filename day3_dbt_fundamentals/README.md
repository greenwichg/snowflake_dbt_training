# Day 3 — Introduction to DBT: Models, Project Structure & Materializations

> 🧠 **New to these topics?** Read [CONCEPTS.md](CONCEPTS.md) first — every concept below explained from zero, with analogies.

> From here on we work inside the [`dbt_training/`](../dbt_training/) project at the repo root.

## Topics Covered

- **What is DBT? — Analytics Engineering Philosophy**: transformations as version-controlled, tested, documented SQL `SELECT`s; dbt is the **T** in ELT, compiling Jinja+SQL and running it inside Snowflake
- **DBT Core vs DBT Cloud**: Core = open-source CLI (what we use, free, runs anywhere); Cloud = managed SaaS adding an IDE, job scheduler, CI hooks, and hosted docs
- **DBT Architecture & Project Structure**: `dbt_project.yml`, `models/`, `seeds/`, `snapshots/`, `macros/`, `tests/`, `target/` (compiled artifacts), `profiles.yml` (connections, lives outside the repo)
- **Connecting DBT with Snowflake**: account/role/warehouse/database/schema, `dbt debug`
- **Models & Materializations**:
  | Materialization | Builds | Use for |
  |---|---|---|
  | `view` (default) | `CREATE VIEW` | staging; cheap, always fresh |
  | `table` | `CREATE TABLE AS` | marts; fast to query |
  | `incremental` | insert/merge only new rows | big fact tables |
  | `ephemeral` | nothing — inlined as a CTE into downstream models | small reusable logic steps |
- **Sources and refs**: `source()` declares raw inputs; `ref()` wires model-to-model dependencies and builds the DAG
- **Jinja Templating**: `{{ }}` expressions, `{% %}` control flow, what compilation produces in `target/compiled/`
- **Seeds & Snapshots**: version-controlled lookup CSVs (`dbt seed`); SCD Type 2 history capture (`dbt snapshot`)

## Hands-On Practice

| # | Exercise |
|---|---|
| 13 | **Install DBT Core locally and configure `profiles.yml`** — follow [`01_setup_dbt_snowflake.md`](01_setup_dbt_snowflake.md) |
| 14 | **Connect DBT project to Snowflake** — `dbt debug` until all green, then `dbt deps` |
| 15 | **Create first staging model and run dbt run** — study [`stg_customers.sql`](../dbt_training/models/staging/stg_customers.sql) + [`_sources.yml`](../dbt_training/models/staging/_sources.yml); `dbt run -s stg_customers`; find the view in Snowsight and the compiled SQL in `target/compiled/` |
| 16 | **Build table, view, and incremental models** — `dbt run`; compare materializations: `stg_*` (views), `dim_customers`/`fct_orders` (tables), `fct_web_events` (incremental — run twice, compare Query History), `int_customer_orders` (ephemeral — find it inlined as a CTE in `dim_customers`' compiled SQL, and note no object exists in Snowflake) |
| 17 | **Use source() and ref() functions** — `dbt ls -s +dim_customers` to walk the DAG; build your own `fct_monthly_revenue` model that `ref()`s `fct_orders` |
| 18 | **Load seed data; create a snapshot** — `dbt seed` (loads [`fx_rates.csv`](../dbt_training/seeds/fx_rates.csv)); `dbt snapshot` (runs [`customers_snapshot.sql`](../dbt_training/snapshots/customers_snapshot.sql)); change a customer's country in `RAW.CUSTOMERS` and snapshot again to see SCD2 rows |

> ✅ **Stuck or done?** Reference answers for the write-it-yourself tasks are in [solutions/](solutions/).

## Learning Outcomes

- ✅ Explain DBT's role in the ELT pipeline
- ✅ Build and execute DBT models of all materialization types
- ✅ Understand DBT project folder structure
- ✅ Use sources, refs, seeds, and snapshots effectively
