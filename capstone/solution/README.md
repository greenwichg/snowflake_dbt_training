# Capstone — Reference Solution

> ⚠️ **Attempt the capstone yourself first.** This is for comparing your finished work (or unblocking yourself after a real attempt) — copying it defeats the point of Days 6–8.

A complete implementation of tasks 31–44: Snowflake setup + a standalone dbt project (`dbt_capstone/`), separate from the training project.

> 🧠 **New to Snowflake/dbt?** Read [WALKTHROUGH.md](WALKTHROUGH.md) alongside running this — it narrates the full execution flow start-to-end: what each command actually does behind the scenes, what exists in Snowflake after every phase, and the exact numbers to expect at each checkpoint.

## How to run it

```bash
# 1. Task 31 — in Snowsight: run snowflake_setup/01_setup_and_load.sql,
#    uploading the three CSVs from capstone/data/ when prompted.

# 2. Configure the connection
cp dbt_capstone/profiles.yml.example ~/.dbt/profiles.yml   # merge if you have profiles already

# 3. Build everything (tasks 32-43)
cd dbt_capstone
dbt debug
dbt build          # models + all tests, DAG-ordered
dbt docs generate && dbt docs serve   # task 43: docs site + lineage
```

## Task → file map

| Task | Where |
|---|---|
| 31 — COPY INTO loads | [`snowflake_setup/01_setup_and_load.sql`](snowflake_setup/01_setup_and_load.sql) |
| 32 — sources | [`dbt_capstone/models/staging/_sources.yml`](dbt_capstone/models/staging/_sources.yml) |
| 33–34 — staging models + cleaning | [`stg_orders`](dbt_capstone/models/staging/stg_orders.sql) · [`stg_customers`](dbt_capstone/models/staging/stg_customers.sql) · [`stg_products`](dbt_capstone/models/staging/stg_products.sql) |
| 35 — generic tests (incl. `accepted_values` on status) | [`_staging.yml`](dbt_capstone/models/staging/_staging.yml) |
| 36 — `stg_orders` incremental (append by order_date) | config block in [`stg_orders.sql`](dbt_capstone/models/staging/stg_orders.sql) |
| 37 — run + test green | `dbt build` (see verification note below) |
| 38 — `mart_daily_sales` | [`models/marts/mart_daily_sales.sql`](dbt_capstone/models/marts/mart_daily_sales.sql) |
| 39 — `mart_customer_summary` | [`models/marts/mart_customer_summary.sql`](dbt_capstone/models/marts/mart_customer_summary.sql) |
| 40 — `mart_product_performance` | [`models/marts/mart_product_performance.sql`](dbt_capstone/models/marts/mart_product_performance.sql) |
| 41 — surrogate key macro | [`macros/surrogate_key.sql`](dbt_capstone/macros/surrogate_key.sql), used in all three marts |
| 42 — relationship tests marts → staging | [`_marts.yml`](dbt_capstone/models/marts/_marts.yml) |
| 43 — docs + lineage | every model/column described in the YAML files; `dbt docs generate` |
| 44 — presentation | below |

## Task 44 — the 5-minute walkthrough

**Architecture (raw data → Gold mart → business insight):**

```
capstone/data/*.csv ──upload──▶ @RAW.CSV_STAGE ──COPY INTO──▶ CAPSTONE_DB.RAW   (Bronze)
                                                                    │  dbt sources + tests
                                                              stg_orders / stg_customers / stg_products   (Silver)
                                                                    │  clean, type, normalize, incremental orders
                                                              mart_daily_sales / mart_customer_summary /
                                                              mart_product_performance                    (Gold)
```

**Business insights to demo (run after `dbt build`):**

```sql
-- Best and worst revenue days
SELECT * FROM mart_daily_sales ORDER BY revenue DESC LIMIT 3;

-- Top customers and which segment carries the business
SELECT customer_name, segment, order_count, lifetime_value
FROM mart_customer_summary ORDER BY lifetime_value DESC LIMIT 5;

SELECT segment, SUM(lifetime_value) AS segment_value, COUNT(*) AS customers
FROM mart_customer_summary GROUP BY segment ORDER BY segment_value DESC;

-- 💥 The headline: units sold BELOW COST hiding inside a profitable product
SELECT product_name, units_sold, below_cost_units, min_unit_price, cost_price, margin
FROM mart_product_performance
WHERE below_cost_units > 0;
-- The 2-Person Tent (cost 95.00) sold at 89.99 on discounted orders: profitable
-- overall, losing money per discounted unit - invisible without this mart.
```

**Live "trust" demo:** insert one new raw order with today's date, `dbt build`, show it flow into the marts via the incremental append — then show the lineage graph and the green test wall.

## Design decisions worth defending in Q&A

- **Append (not merge) incremental for `stg_orders`** — matches the task ("append by order_date") and is safe with a strict `>` high-water mark; the trade-off is that *updated* historical rows wouldn't be re-picked. If statuses could change retroactively, switch to `unique_key='order_id'` merge.
- **Revenue = completed only**; cancellations/returns surfaced as separate counts rather than silently dropped.
- **NULL policy** — `segment → 'unassigned'`, `supplier_id → 'unknown'` (keeps aggregations complete); `city` stays NULL (don't invent facts). Every choice is documented in the staging model.
- **LEFT JOINs in customer/product marts** — zero-order customers and unsold products must appear with zeros, or averages lie.
- **Margin computed per line** — the same product sells at different (discounted) prices, so margin must use the line's `unit_price`, not the catalog price.

## Verification status

The dbt project was validated end-to-end against the fakesnow emulator: the 3 raw CSVs loaded, all 6 models built, **all 32 tests passed**, and the `is_incremental()` filter was verified to pick up exactly a newly inserted order (via the compiled SQL — the emulator can't execute dbt's temp-table staging step, which is standard on real Snowflake). The Snowflake setup script follows the same patterns as the Day 1 labs but, like them, needs a real account to execute.
