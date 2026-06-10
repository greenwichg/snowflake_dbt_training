-- Mart: customer dimension enriched with lifetime order metrics.
-- Pattern: staging → intermediate → mart. int_customer_orders is ephemeral,
-- so it compiles into a CTE here rather than existing in Snowflake.

with customers as (

    select * from {{ ref('stg_customers') }}

),

customer_orders as (

    select * from {{ ref('int_customer_orders') }}

)

select
    customers.customer_id,
    customers.first_name,
    customers.last_name,
    customers.email,
    customers.country_code,
    customers.signup_date,
    customers.is_active,
    coalesce(customer_orders.lifetime_orders, 0)    as lifetime_orders,
    coalesce(customer_orders.lifetime_value_usd, 0) as lifetime_value_usd,
    customer_orders.first_order_date,
    customer_orders.most_recent_order_date

from customers
left join customer_orders
    on customer_orders.customer_id = customers.customer_id
