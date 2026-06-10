-- Singular test (Day 4): fails if any completed order has non-positive revenue.
-- A test passes when it returns zero rows.

select
    order_id,
    amount_usd

from {{ ref('fct_orders') }}
where status = 'completed'
  and amount_usd <= 0
