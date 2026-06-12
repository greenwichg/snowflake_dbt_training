-- Tasks 33/34 — staging products: rename, type, handle NULLs.
-- supplier_id: NULL → 'unknown' so supplier-level aggregations keep every product.

with source as (

    select * from {{ source('raw', 'products') }}

)

select
    product_id,
    trim(name)                              as product_name,
    trim(category)                          as category,
    cost_price,
    coalesce(trim(supplier_id), 'unknown')  as supplier_id

from source
