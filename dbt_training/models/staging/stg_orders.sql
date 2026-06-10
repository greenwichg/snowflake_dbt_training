-- Staging: typed, renamed orders with USD normalization via seed + macro.

with source as (

    select * from {{ source('raw', 'orders') }}

)

select
    order_id,
    customer_id,
    order_date,
    lower(status)                                              as status,
    upper(currency)                                            as currency,
    amount                                                     as amount_local,
    {{ convert_to_usd('source.amount', 'source.currency') }}   as amount_usd

from source
