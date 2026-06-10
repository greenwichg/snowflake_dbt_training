# Day 3 — Solutions

Reference answers for the write-it-yourself parts of Day 3. Try the exercise first; peek here to compare.

## Exercise 17 — build your own `fct_monthly_revenue`

Copy [`fct_monthly_revenue.sql`](fct_monthly_revenue.sql) into `dbt_training/models/marts/`, then:

```bash
dbt run -s fct_monthly_revenue
```

Points worth comparing against your attempt:

- It refs **`fct_orders`** (a mart), not `stg_orders` — reuse the cleaned, USD-normalized layer instead of redoing that work.
- Filtering to `status = 'completed'` happens in a CTE at the top, so the intent is visible at a glance.
- `date_trunc('month', …)` is the standard way to get a month bucket you can sort and join on.
- It inherits the folder default materialization (`table`) — no config block needed.

A good follow-up: add the model to `_marts.yml` with a description and a `not_null` test on `order_month` — from Day 4 onward that's expected for every new model.
