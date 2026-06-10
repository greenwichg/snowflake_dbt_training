# Exercise 28 — Debug a Broken Model (schema drift, bad ref)

Break the pipeline two ways on purpose, then practice the debugging workflow:

> read the error → `dbt compile -s <model>` → run the compiled SQL from `target/compiled/` in Snowsight → fix → `dbt build -s <model>+`

## Scenario A — Bad ref

1. In `models/marts/dim_customers.sql`, change `{{ ref('int_customer_orders') }}` to `{{ ref('int_customer_orderz') }}` and run `dbt run -s dim_customers`.

2. Note what happens: dbt fails at **compile time**, before touching Snowflake —
   ```
   Compilation Error in model dim_customers
     Model 'model.dbt_training.dim_customers' depends on a node named 'int_customer_orderz' which was not found
   ```
   This is the value of `ref()`: dependency typos can never reach the warehouse. Fix it back and re-run.

## Scenario B — Schema drift

Simulate an upstream team renaming a column in the source system:

1. In Snowsight:
   ```sql
   ALTER TABLE TRAINING_DB.RAW.ORDERS RENAME COLUMN AMOUNT TO ORDER_AMOUNT;
   ```

2. `dbt run` — observe the **runtime** failure in `stg_orders`:
   ```
   Database Error in model stg_orders
     000904 (42000): SQL compilation error: invalid identifier 'AMOUNT'
   ```

3. Practice the workflow:
   - `dbt compile -s stg_orders` and open `target/compiled/dbt_training/models/staging/stg_orders.sql`
   - Run that SQL in Snowsight — same error, now interactive; `DESCRIBE TABLE TRAINING_DB.RAW.ORDERS` reveals the drift
   - Note the blast radius: `dbt ls -s stg_orders+` shows every downstream model that would have built on the failure (with `dbt build`, they'd all be skipped — fail-fast)

4. Decide how to fix — both are legitimate:
   - **Absorb in staging** (usual choice): `order_amount as amount_local` in `stg_orders.sql` — downstream models never notice. This is *why* staging exists.
   - **Revert the source**: `ALTER TABLE ... RENAME COLUMN ORDER_AMOUNT TO AMOUNT;` (do this for our training repo so scripts keep working)

5. Re-run `dbt build -s stg_orders+` until green.

## Discussion

- Which failures does `dbt build` catch that `dbt run` doesn't? (Test failures gate downstream models.)
- How would the `dim_customers` **data contract** (Day 4) have surfaced a drift that changed a column *type* instead of its name?
- What detects drift *before* the nightly run? (Source `not_null`/`unique` tests, `dbt source freshness`, CI running `dbt build` on every PR.)
