-- Mart: order fact table, one row per order, with customer attributes
-- and per-customer order sequencing.

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
    orders.amount_usd,
    row_number() over (
        partition by orders.customer_id
        order by orders.order_date, orders.order_id
    )                                        as customer_order_seq,
    orders.amount_usd = max(orders.amount_usd) over (
        partition by orders.customer_id
    )                                        as is_largest_order

from orders
left join customers
    on customers.customer_id = orders.customer_id
