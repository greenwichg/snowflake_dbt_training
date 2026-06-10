-- Intermediate: per-customer lifetime order metrics (completed orders only).
-- Materialized EPHEMERAL: builds no object in Snowflake — dbt inlines this
-- query as a CTE into every model that ref()s it (see dim_customers'
-- compiled SQL in target/compiled/).

with orders as (

    select * from {{ ref('stg_orders') }}
    where status = 'completed'

)

select
    customer_id,
    count(*)            as lifetime_orders,
    sum(amount_usd)     as lifetime_value_usd,
    min(order_date)     as first_order_date,
    max(order_date)     as most_recent_order_date

from orders
group by customer_id
