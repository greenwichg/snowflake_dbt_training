-- Mart: customer dimension enriched with lifetime order metrics.

with customers as (

    select * from {{ ref('stg_customers') }}

),

orders as (

    select * from {{ ref('stg_orders') }}
    where status = 'completed'

),

customer_orders as (

    select
        customer_id,
        count(*)            as lifetime_orders,
        sum(amount_usd)     as lifetime_value_usd,
        min(order_date)     as first_order_date,
        max(order_date)     as most_recent_order_date

    from orders
    group by customer_id

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
