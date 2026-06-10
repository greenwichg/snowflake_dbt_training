-- Solution: Day 3, Exercise 17 — monthly revenue from fct_orders.
-- Place in dbt_training/models/marts/fct_monthly_revenue.sql

with completed_orders as (

    select * from {{ ref('fct_orders') }}
    where status = 'completed'

)

select
    order_month,
    count(*)                          as order_count,
    sum(amount_usd)                   as revenue_usd,
    round(avg(amount_usd), 2)         as avg_order_value_usd,
    count(distinct customer_id)       as active_customers

from completed_orders
group by order_month
order by order_month
