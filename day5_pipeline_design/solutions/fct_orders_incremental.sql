-- Solution: Day 5, Exercise 27 — fct_orders converted to incremental (merge).
-- In practice: apply these edits to models/marts/fct_orders.sql, then run
--   dbt run -s fct_orders --full-refresh
-- once to rebuild the table under the new strategy.
--
-- ⚠ See solutions/README.md: the window-function columns make incremental
--   semantically wrong here; this file demonstrates the MECHANICS asked for
--   by the exercise. (Window columns are dropped for that reason.)

{{
    config(
        materialized='incremental',
        unique_key='order_id'
    )
}}

with orders as (

    select * from {{ ref('stg_orders') }}

),

customers as (

    select * from {{ ref('stg_customers') }}

)

select
    orders.order_id,
    orders.customer_id,
    customers.country_code,
    orders.order_date,
    date_trunc('month', orders.order_date)  as order_month,
    orders.status,
    orders.currency,
    orders.amount_local,
    orders.amount_usd

from orders
left join customers
    on customers.customer_id = orders.customer_id

{% if is_incremental() %}
  -- >= (not >) so boundary-day updates are re-picked; the merge on
  -- order_id dedupes anything fetched twice
  where orders.order_date >= (select coalesce(max(order_date), '1900-01-01') from {{ this }})
{% endif %}
