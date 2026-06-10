# Days 6–8 — 2-Day Capstone Project: Retail Sales Analytics Platform

**Snowflake + DBT Only | End-to-End Implementation**

## Business Context

You are a Data Engineer at a mid-size retail company. The business team needs a self-service analytics layer to track **daily sales performance**, **customer behavior**, and **product profitability**. Raw transactional data lands in Snowflake as CSV drops (orders, customers, products). Your job is to build a clean, tested, documented DBT pipeline on top of it.

## Source Datasets (load as CSV into Snowflake RAW schema)

Sample files are provided in [`data/`](data/) — feel free to extend them with more rows.

| File | Columns |
|---|---|
| [`orders.csv`](data/orders.csv) | `order_id, customer_id, product_id, order_date, quantity, unit_price, status` |
| [`customers.csv`](data/customers.csv) | `customer_id, name, city, country, signup_date, segment` |
| [`products.csv`](data/products.csv) | `product_id, name, category, cost_price, supplier_id` |

> The data is deliberately messy: inconsistent `status` casing, NULL `city`/`segment`/`supplier_id` values, and at least one product selling below cost. Your cleaning (task 34) and your marts (tasks 38–40) should handle and surface all of this.

---

## Day 6 — Data Ingestion + Bronze & Silver Layers *(Capstone Day 1 of 2)*

### Tasks to Complete

| # | Task |
|---|---|
| 31 | Load all 3 CSVs into Snowflake RAW schema using **COPY INTO** |
| 32 | Create DBT **sources** pointing to RAW schema tables |
| 33 | Build `stg_orders`, `stg_customers`, `stg_products` staging models |
| 34 | Apply data cleaning: cast types, rename columns, handle nulls |
| 35 | Add generic tests: `not_null`, `unique`, `accepted_values` on status |
| 36 | Implement `stg_orders` as **incremental** (append by `order_date`) |
| 37 | Run `dbt run` + `dbt test` and fix all failures |

### Deliverables / Checkpoints

- ✅ Snowflake RAW schema with 3 loaded tables
- ✅ DBT staging models (Silver layer) — clean, typed, tested
- ✅ All dbt tests passing
- ✅ Incremental load working for orders

---

## Day 7 — Gold Layer, Documentation & Presentation *(Capstone Day 2 of 2)*

### Tasks to Complete

| # | Task |
|---|---|
| 38 | Build `mart_daily_sales`: daily revenue, order count, avg order value |
| 39 | Build `mart_customer_summary`: lifetime value, order count per customer |
| 40 | Build `mart_product_performance`: revenue, margin, units sold per product |
| 41 | Write a **macro for surrogate key generation** (`dbt_utils` or custom) |
| 42 | Add **relationship tests** between marts and staging models |
| 43 | Generate **dbt docs** and verify full lineage graph |
| 44 | Present: architecture diagram → raw data → Gold mart → business insight |

### Deliverables / Checkpoints

- ✅ 3 Gold mart models fully built and tested
- ✅ Surrogate key macro in use
- ✅ dbt docs site with lineage graph
- ✅ 5-min architecture walkthrough ready to present

---

## Day 8 — Demo to Stakeholders and Team

**Tasks:** Demo to stakeholders and team. **Deliverable:** Q&A from team members.

A strong demo covers, in ~5 minutes:
1. **Architecture diagram** — CSV drops → stage/COPY INTO → RAW (Bronze) → staging (Silver) → marts (Gold) → BI
2. **Live lineage** — walk the dbt docs graph from `raw.orders` to `mart_daily_sales`
3. **One business insight from each mart** — e.g. best/worst revenue day, top customer segment by lifetime value, and the product that *loses money* per unit (it's in the data — find it)
4. **Trust story** — show `dbt build` running green: tests on every key, accepted statuses, relationships between layers
5. **Q&A** — be ready for: Why incremental on orders? What happens on `--full-refresh`? How would Snowpipe replace the manual COPY? What changes at 100× volume?

---

## Hints — where you learned each task

| Tasks | Refer back to |
|---|---|
| 31 | Day 1, Exercise 3 (file formats, stages, COPY INTO) |
| 32–34 | Day 3 (sources, staging models) + Day 5 (folder conventions) |
| 35, 42 | Day 4 (generic tests; relationships) |
| 36 | Day 4–5 (incremental patterns, `is_incremental()`) |
| 38–40 | Day 1, Exercise 6 (analytical SQL) + Day 3 (marts) |
| 41 | Day 4 (macros); see `dbt_utils.generate_surrogate_key` |
| 43 | Day 4 (docs & lineage) |
| 44 | Day 5 (Medallion architecture) |

### Ground rules

- Work in a **clean database** (e.g. `CAPSTONE_DB`) — rebuilding from zero is the real test of Days 1–5.
- No UI-wizard loads (task 31 says COPY INTO), and all transformations in dbt — **Snowflake + DBT only**.
- Commit everything (setup SQL + dbt project + README with run instructions) to a Git repo.
