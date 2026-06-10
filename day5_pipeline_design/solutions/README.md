# Day 5 — Solutions

Reference answers for the write-it-yourself parts of Day 5.

## Exercise 26 — wire dbt models to the Medallion layers

The final `models:` block in `dbt_project.yml`:

```yaml
models:
  dbt_training:
    staging:
      +materialized: view
      +schema: silver
    intermediate:
      +materialized: ephemeral
    marts:
      +materialized: table
      +schema: gold
```

After `dbt run`, staging views land in `<your_schema>_SILVER` and marts in `<your_schema>_GOLD`. Why the prefix? dbt's default `generate_schema_name` macro *appends* the custom schema to your target schema, so two developers never collide (`DBT_SAI_GOLD` vs `DBT_ANA_GOLD`). In production you override that macro so the prod target writes to exactly `SILVER` / `GOLD`. Note the `intermediate` folder needs no schema — ephemeral models build nothing.

## Exercise 27 — convert `fct_orders` to incremental

[`fct_orders_incremental.sql`](fct_orders_incremental.sql) is the converted model — in practice you'd apply these edits to `fct_orders.sql` itself, then run once with `--full-refresh`.

What changed and why:

- `materialized='incremental', unique_key='order_id'` → dbt **merges** on `order_id`: rows already present get updated, new rows inserted. We use merge (not plain append) because order rows *can* change — a status flips to `refunded`.
- The `is_incremental()` filter uses `>=` (not `>`) so rows updated on the boundary day are re-picked; the merge dedupes them.

**The honest caveat (this is the real lesson of the exercise):** `fct_orders` contains window functions over *each customer's full history* (`customer_order_seq`, `is_largest_order`). On an incremental run those windows only see the **new batch**, so the sequence numbers would be wrong. For this model the correct engineering answer is: **keep it a full-rebuild table** (it's tiny), or move the window columns to a separate always-full model. Incremental is for tables where rebuild *cost* hurts — and it always trades away simplicity. If your solution noticed this problem, you did better than the exercise expected.

## Exercise 28 — debug the broken model

The fixes are walked through step-by-step in [`../exercises/28_debug_broken_model.md`](../exercises/28_debug_broken_model.md) (Scenario A: fix the ref typo; Scenario B: absorb the rename in staging with `order_amount as amount_local`, or revert the source rename).

## Exercise 29 — find dbt's most expensive model

With `query_tag: dbt` set in `profiles.yml`, after a `dbt run`:

```sql
select query_text,
       total_elapsed_time / 1000          as seconds,
       partitions_scanned, partitions_total,
       bytes_spilled_to_remote_storage
from snowflake.account_usage.query_history
where query_tag = 'dbt'
  and start_time > dateadd('hour', -1, current_timestamp())
order by total_elapsed_time desc
limit 10;
```

(`account_usage` views lag up to ~45 min; for instant results use the Query History page filtered by tag, or `information_schema.query_history()`.) Cross-check with dbt's own per-model timings printed by `dbt run`.
