-- Solution: Day 4, Exercise 20 — dim_customers extended with web activity.
-- This replaces dbt_training/models/marts/dim_customers.sql
-- ⚠ dim_customers has an ENFORCED CONTRACT: you must also add the three new
--   columns to its contract in _marts.yml (see solutions/README.md), or the
--   build will fail by design.

with customers as (

    select * from {{ ref('stg_customers') }}

),

customer_orders as (

    select * from {{ ref('int_customer_orders') }}

),

web_activity as (

    select * from {{ ref('int_customer_web_activity') }}

)

select
    customers.customer_id,
    customers.first_name,
    customers.last_name,
    customers.email,
    customers.country_code,
    customers.signup_date,
    customers.is_active,
    coalesce(customer_orders.lifetime_orders, 0)::integer           as lifetime_orders,
    coalesce(customer_orders.lifetime_value_usd, 0)::number(12, 2)  as lifetime_value_usd,
    customer_orders.first_order_date,
    customer_orders.most_recent_order_date,
    coalesce(web_activity.web_events, 0)::integer                   as web_events,
    coalesce(web_activity.web_purchases, 0)::integer                as web_purchases,
    web_activity.last_seen_at

from customers
left join customer_orders
    on customer_orders.customer_id = customers.customer_id
left join web_activity
    on web_activity.customer_id = customers.customer_id
