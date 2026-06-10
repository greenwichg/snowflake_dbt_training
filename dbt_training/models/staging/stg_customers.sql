-- Staging: rename, type, and lightly clean raw customers. No business logic.

with source as (

    select * from {{ source('raw', 'customers') }}

)

select
    customer_id,
    initcap(first_name)                          as first_name,
    initcap(last_name)                           as last_name,
    lower(email)                                 as email,
    upper(country)                               as country_code,
    signup_date,
    is_active

from source
