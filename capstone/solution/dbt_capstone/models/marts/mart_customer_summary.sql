-- Task 39 — lifetime value and order count per customer.
-- LEFT JOIN from customers so prospects with zero orders still appear
-- (their absence would silently skew "average customer value").

with customers as (

    select * from {{ ref('stg_customers') }}

),

orders as (

    select * from {{ ref('stg_orders') }}
    where status = 'completed'

),

per_customer as (

    select
        customer_id,
        count(*)              as order_count,
        sum(gross_revenue)    as lifetime_value,
        min(order_date)       as first_order_date,
        max(order_date)       as most_recent_order_date

    from orders
    group by customer_id

)

select
    {{ surrogate_key(['customers.customer_id']) }}           as customer_key,
    customers.customer_id,
    customers.customer_name,
    customers.city,
    customers.country_code,
    customers.segment,
    customers.signup_date,
    coalesce(per_customer.order_count, 0)                    as order_count,
    coalesce(per_customer.lifetime_value, 0)::number(12,2)   as lifetime_value,
    per_customer.first_order_date,
    per_customer.most_recent_order_date

from customers
left join per_customer
    on per_customer.customer_id = customers.customer_id
