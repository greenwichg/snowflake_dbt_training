# Day 4 — Solutions

Reference answers for the write-it-yourself parts of Day 4. Try each exercise first.

## Exercise 19 — the `pct()` macro

Copy [`pct.sql`](pct.sql) into `dbt_training/macros/`. Example use — month-over-month growth in your Day 3 `fct_monthly_revenue`:

```sql
select
    order_month,
    revenue_usd,
    lag(revenue_usd) over (order by order_month)                          as prev_revenue,
    {{ pct('revenue_usd - prev_revenue', 'prev_revenue') }}               as growth_pct
from ...
```

Key detail: `nullif(denominator, 0)` turns division-by-zero into NULL instead of an error — the whole reason to centralize this in a macro.

## Exercise 20 — `int_customer_web_activity` joined into `dim_customers`

1. Copy [`int_customer_web_activity.sql`](int_customer_web_activity.sql) into `dbt_training/models/intermediate/` (the folder config makes it ephemeral automatically).
2. Replace `dim_customers.sql` with [`dim_customers__with_web_activity.sql`](dim_customers__with_web_activity.sql) (rename it to `dim_customers.sql`).
3. **The build will now fail — on purpose.** `dim_customers` has an *enforced contract* (Day 4 topic!), and you just added columns the contract doesn't know. Extend its `columns:` list in `_marts.yml`:

```yaml
      - name: web_events
        data_type: number
      - name: web_purchases
        data_type: number
      - name: last_seen_at
        data_type: timestamp_ntz
```

That failure is the contract doing its job: nobody changes the shape of `dim_customers` casually — not even you.

Notes on the int model itself: it filters out `customer_id is null` (anonymous events can't join to a customer), and uses `count(case when … then 1 end)` for conditional counts.

## Exercise 21 — `accepted_values` on `stg_web_events.device`

In `models/staging/_staging.yml`, under `stg_web_events`:

```yaml
      - name: device
        tests:
          - accepted_values:
              arguments:
                values: ['mobile', 'desktop', 'tablet']
```

Check what values actually exist first (`select distinct device from …`) — an accepted-values test invented from memory just fails on day one.

## Exercise 22 — singular test: no order predates its customer's signup

Copy [`assert_orders_after_signup.sql`](assert_orders_after_signup.sql) into `dbt_training/tests/`, then `dbt test -s assert_orders_after_signup`.

The pattern for every singular test: **select the rows that violate the rule** — passing means the query returns nothing. Selecting the violating columns (not just `count(*)`) matters: when the test fails, the stored failures tell you *which* orders to investigate.
