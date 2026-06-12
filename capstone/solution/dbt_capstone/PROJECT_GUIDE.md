# dbt_capstone — Project Guide: every file, the execution flow, and the lineage

A file-by-file map of this project: what each file is for, what "runs" (and what never runs), in what order, and how data flows between them.

> Companion docs: [`../WALKTHROUGH.md`](../WALKTHROUGH.md) explains the same pipeline as *phases over time* (with Snowflake setup); this guide explains it as *files and their relationships*.

---

## 1. The most important idea first: there is no "main file"

If you come from programming, you'll look for an entry point — a `main()` that calls everything else in order. **dbt has none.** Here is what actually determines execution:

- **The entry point is a *command*, not a file:** you type `dbt build` (or `dbt run` / `dbt test`). That command is the trigger.
- **The execution order is *derived*, not written down anywhere:** dbt reads every model file, finds its `{{ ref('…') }}` and `{{ source('…') }}` calls, and computes the dependency graph (DAG). A model runs only after everything it refs has finished. Nobody maintains a run-order list — **the order falls out of the `ref()` calls**.
- **File names and folder order don't matter for execution.** Renaming `mart_daily_sales.sql` to `aaa.sql` changes which object gets created, but not *when* it runs. Only the refs matter.

So "which file executes first?" has a two-part answer: dbt always *reads* `dbt_project.yml` first (configuration), and then *executes* whatever models have no upstream models — here, the three staging models.

## 2. Purpose of every file

```
dbt_capstone/
├── dbt_project.yml            ← read FIRST by every dbt command (config, never "runs")
├── profiles.yml.example       ← template for ~/.dbt/profiles.yml (connection, never "runs")
├── .gitignore                 ← keeps generated folders & credentials out of Git
├── macros/
│   └── surrogate_key.sql      ← a reusable function; only runs INSIDE models that call it
└── models/
    ├── staging/               ── Silver layer ──
    │   ├── _sources.yml       ← declares the 3 RAW tables + tests on them (data entry point)
    │   ├── stg_orders.sql     ← cleans orders; INCREMENTAL table
    │   ├── stg_customers.sql  ← cleans customers; view
    │   ├── stg_products.sql   ← cleans products; view
    │   └── _staging.yml       ← tests + docs for the 3 staging models
    └── marts/                 ── Gold layer ──
        ├── mart_daily_sales.sql          ← revenue/orders/AOV per day; table
        ├── mart_customer_summary.sql     ← lifetime value per customer; table
        ├── mart_product_performance.sql  ← revenue/margin per product; table
        └── _marts.yml         ← tests + docs for the 3 marts
```

### Configuration files (read, never executed)

| File | Purpose | When dbt uses it |
|---|---|---|
| `dbt_project.yml` | The project's identity card: its name, which profile to use, and folder-level defaults — `staging/` builds as **views**, `marts/` as **tables**. A config block *inside* a model (like `stg_orders`' incremental config) overrides the folder default. | First thing read by **every** dbt command |
| `profiles.yml.example` → your `~/.dbt/profiles.yml` | *How to log in*: account, user, role, warehouse, and the target database/schema (`CAPSTONE_DB.ANALYTICS`). Lives outside the repo so credentials never reach Git. | Read right after `dbt_project.yml`, before connecting |
| `.gitignore` | Excludes `target/` & `logs/` (regenerated every run) and any real `profiles.yml`. | Git only — dbt ignores it |

### YAML files (declarations — they *generate* tests and docs)

A common beginner confusion: `.yml` files are **not executed as SQL**. They declare facts, and dbt turns some of those facts into runnable tests:

| File | Declares | What dbt generates from it |
|---|---|---|
| `_sources.yml` | "Tables `raw.orders/customers/products` exist in `CAPSTONE_DB.RAW`, loaded by something outside dbt" — this is the **data entry point** of the whole project | 6 *source tests* (`unique` + `not_null` on each raw primary key) that run **before** any model is built; plus it makes `{{ source('raw', 'orders') }}` resolvable |
| `_staging.yml` | Descriptions + quality rules for the 3 staging models | 13 tests (keys, `accepted_values` on `status` & `segment`) that run right after staging builds |
| `_marts.yml` | Descriptions + quality rules for the 3 marts | 13 tests (surrogate & natural keys, `relationships` back to staging) that run right after marts build |

### The macro (a library, not a step)

`macros/surrogate_key.sql` defines a Jinja function. It **never runs on its own** and never appears in the DAG. When a mart contains `{{ surrogate_key(['sales_date']) }}`, dbt expands it into a literal `md5(coalesce(cast(…)))` expression *at compile time* — Snowflake only ever sees the expanded SQL (look in `target/compiled/` to see it). Think of it as `#include`, not as a pipeline step.

### Model files (the things that actually execute)

| File | Reads from (upstream) | Builds | Key logic |
|---|---|---|---|
| `stg_orders.sql` | `source('raw','orders')` | **incremental table** `ANALYTICS.STG_ORDERS` | `lower(trim(status))`; computes `gross_revenue = quantity × unit_price`; on re-runs appends only rows with `order_date` past the high-water mark |
| `stg_customers.sql` | `source('raw','customers')` | view `STG_CUSTOMERS` | trims names; `segment NULL → 'unassigned'` |
| `stg_products.sql` | `source('raw','products')` | view `STG_PRODUCTS` | `supplier_id NULL → 'unknown'` |
| `mart_daily_sales.sql` | `ref('stg_orders')` | table `MART_DAILY_SALES` | groups by day; completed-only revenue; avg order value |
| `mart_customer_summary.sql` | `ref('stg_customers')`, `ref('stg_orders')` | table `MART_CUSTOMER_SUMMARY` | LEFT JOIN keeps zero-order customers; lifetime value |
| `mart_product_performance.sql` | `ref('stg_products')`, `ref('stg_orders')` | table `MART_PRODUCT_PERFORMANCE` | margin per line (price varies per order); below-cost units |

### Generated folders (never edit, never commit)

`target/` — everything dbt produced last run: `compiled/` (your models with Jinja expanded — pure SQL, the best debugging aid in the project), `run/` (the exact DDL sent to Snowflake), and the docs site. `logs/` — execution logs. Both are rebuilt constantly and gitignored.

## 3. The execution flow of `dbt build`, start to finish

```
 START: you type `dbt build`
   │
   │ ① READ  dbt_project.yml ......... which folders, which defaults, which profile
   │ ② READ  ~/.dbt/profiles.yml ..... how to log in, where to build
   │ ③ PARSE every file in models/ & macros/ — collect ref()/source() calls,
   │         derive the DAG, expand macros. No SQL sent to Snowflake yet;
   │         a typo'd ref fails HERE, before touching the warehouse.
   │
   │ ④ SOURCE TESTS (from _sources.yml) — guard the raw input
   │      6 tests: unique/not_null on raw orders/customers/products keys
   ▼
   │ ⑤ WAVE 1 — models with no model-dependencies (run in parallel):
   │      stg_orders (incremental) · stg_customers (view) · stg_products (view)
   │
   │ ⑥ WAVE 1 TESTS (from _staging.yml) — 13 tests.
   │      Any failure ⇒ every downstream mart is SKIPPED, not built wrong.
   ▼
   │ ⑦ WAVE 2 — models whose refs are now all satisfied (parallel):
   │      mart_daily_sales · mart_customer_summary · mart_product_performance
   │
   │ ⑧ WAVE 2 TESTS (from _marts.yml) — 13 tests, incl. relationships
   │      proving every mart key still exists in staging.
   ▼
 END: summary line `PASS=38` — 6 models + 32 tests.
      Endpoints = the 3 mart tables: nothing refs them; analysts query them.
```

Two things worth noticing: models inside a wave run **in parallel** (the `threads` setting in your profile), which is only safe *because* order comes from the DAG; and tests are interleaved with builds — `dbt build` is "build a thing, immediately verify it, only then let dependents proceed."

## 4. Lineage: how data flows file-to-file

```
                            ┌────────────────────[_sources.yml declares + tests]
 CSV files ──COPY INTO──▶  CAPSTONE_DB.RAW (orders 60 / customers 15 / products 10)
 (outside dbt: see                │
 ../snowflake_setup/)             │
                ┌─────────────────┼──────────────────────┐
                ▼                 ▼                      ▼
        stg_customers.sql   stg_orders.sql        stg_products.sql
         15 rows (view)     60 rows (incr. table)  10 rows (view)
         clean segment      clean status,          clean supplier
                │           + gross_revenue         │
                │                │                  │
        ┌───────┴───────┐ ┌──────┼──────────┐       │
        ▼               ▼ ▼      ▼          ▼       ▼
        mart_customer_summary  mart_daily  mart_product_performance
        .sql — 15 rows         _sales.sql  .sql — 10 rows
        (customers ⟕ orders)   60 rows     (products ⟕ orders)
        lifetime value         per-day     margin & below-cost units
                                revenue
```

Read the arrows as *column flow*: `gross_revenue`, computed **once** in `stg_orders`, is what all three marts aggregate — daily revenue, lifetime value, and product revenue are all sums of that same column at different grains. The cleaned `status` likewise filters "completed" in every mart. That's the payoff of layering: compute/clean once in Silver, reuse everywhere in Gold. (⟕ = LEFT JOIN: keep all customers/products even with zero orders.)

This same lineage, interactive and clickable, is what `dbt docs generate && dbt docs serve` renders — this document is the static version of that graph.

## 5. See the flow yourself (2 minutes)

```bash
dbt ls -s +mart_customer_summary     # everything UPSTREAM of a mart (its inputs)
dbt ls -s stg_orders+                # everything DOWNSTREAM of stg_orders (its blast radius)
dbt build -s stg_orders+             # rebuild just that slice of the graph
cat target/compiled/dbt_capstone/models/marts/mart_daily_sales.sql
                                     # the mart with ref() and the macro expanded to pure SQL
```

If you remember one thing: **`ref()` is the project's wiring.** Every relationship in section 4, every wave in section 3, and the entire docs lineage graph are all derived from those calls — change the refs and you've changed the pipeline.
