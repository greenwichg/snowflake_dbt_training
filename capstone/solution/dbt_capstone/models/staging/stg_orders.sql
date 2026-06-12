-- Tasks 33/34/36 — staging orders: typed, cleaned, INCREMENTAL (append by order_date).
--
-- Cleaning (task 34): normalize status casing/whitespace, compute line revenue.
-- Incremental (task 36): append-only — each run inserts only rows with an
-- order_date newer than what's already loaded. Append (no unique_key) is safe
-- here because we filter strictly greater-than the high-water mark.
-- Recovery: dbt run -s stg_orders --full-refresh

{{
    config(
        materialized='incremental',
        incremental_strategy='append'
    )
}}

with source as (

    select * from {{ source('raw', 'orders') }}

)

select
    order_id,
    customer_id,
    product_id,
    order_date,
    quantity,
    unit_price,
    (quantity * unit_price)::number(12,2)   as gross_revenue,
    lower(trim(status))                     as status

from source

{% if is_incremental() %}
  -- append by order_date: only days newer than the current high-water mark
  where order_date > (select coalesce(max(order_date), '1900-01-01') from {{ this }})
{% endif %}
