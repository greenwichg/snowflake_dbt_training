-- Solution: Day 4, Exercise 22 — singular test.
-- Rule: no order may predate its customer's signup date.
-- Place in dbt_training/tests/assert_orders_after_signup.sql
-- A test passes when it returns zero rows.

select
    orders.order_id,
    orders.customer_id,
    orders.order_date,
    customers.signup_date

from {{ ref('stg_orders') }} orders
join {{ ref('stg_customers') }} customers
    on customers.customer_id = orders.customer_id
where orders.order_date < customers.signup_date
