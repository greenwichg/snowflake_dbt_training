-- Task 38 — daily revenue, order count, avg order value.
-- Revenue = completed orders only; cancellations/returns tracked separately
-- so the business can see them without polluting revenue.

with orders as (

    select * from {{ ref('stg_orders') }}

),

daily as (

    select
        order_date                                                as sales_date,
        count(case when status = 'completed' then 1 end)          as order_count,
        sum(case when status = 'completed' then gross_revenue end) as revenue,
        count(case when status = 'cancelled' then 1 end)          as cancelled_orders,
        count(case when status = 'returned'  then 1 end)          as returned_orders

    from orders
    group by order_date

)

select
    {{ surrogate_key(['sales_date']) }}                  as daily_sales_key,
    sales_date,
    coalesce(order_count, 0)                             as order_count,
    coalesce(revenue, 0)::number(12,2)                   as revenue,
    round(revenue / nullif(order_count, 0), 2)           as avg_order_value,
    cancelled_orders,
    returned_orders

from daily
order by sales_date
