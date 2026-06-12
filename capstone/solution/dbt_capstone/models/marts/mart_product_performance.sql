-- Task 40 — revenue, margin, units sold per product.
-- margin = (unit_price - cost_price) * quantity, computed per line because
-- the same product sells at different prices (discounts) across orders.
-- This is the mart that exposes the product LOSING money per unit.

with products as (

    select * from {{ ref('stg_products') }}

),

order_lines as (

    select * from {{ ref('stg_orders') }}
    where status = 'completed'

),

per_product as (

    select
        order_lines.product_id,
        sum(order_lines.quantity)                                   as units_sold,
        sum(order_lines.gross_revenue)                              as revenue,
        sum(order_lines.quantity * products.cost_price)             as total_cost,
        sum(order_lines.gross_revenue
            - order_lines.quantity * products.cost_price)           as margin,
        -- units sold BELOW cost: a product can be profitable overall yet lose
        -- money on discounted lines - exactly the insight the business wants
        sum(case when order_lines.unit_price < products.cost_price
                 then order_lines.quantity end)                     as below_cost_units,
        min(order_lines.unit_price)                                 as min_unit_price

    from order_lines
    join products
        on products.product_id = order_lines.product_id
    group by order_lines.product_id

)

select
    {{ surrogate_key(['products.product_id']) }}        as product_key,
    products.product_id,
    products.product_name,
    products.category,
    products.supplier_id,
    products.cost_price,
    coalesce(per_product.units_sold, 0)                 as units_sold,
    coalesce(per_product.revenue, 0)::number(12,2)      as revenue,
    coalesce(per_product.margin, 0)::number(12,2)       as margin,
    round(100 * per_product.margin
              / nullif(per_product.revenue, 0), 1)      as margin_pct,
    coalesce(per_product.below_cost_units, 0)           as below_cost_units,
    per_product.min_unit_price

from products
left join per_product
    on per_product.product_id = products.product_id
