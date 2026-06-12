-- Tasks 33/34 — staging customers: rename, type, handle NULLs.
-- NULL handling decisions (document yours in the presentation!):
--   * segment: NULL → 'unassigned' (keeps GROUP BYs complete, no silent drops)
--   * city:    left NULL (don't invent geography), but trimmed/empty-proofed

with source as (

    select * from {{ source('raw', 'customers') }}

)

select
    customer_id,
    trim(name)                              as customer_name,
    nullif(trim(city), '')                  as city,
    upper(trim(country))                    as country_code,
    signup_date,
    coalesce(lower(trim(segment)), 'unassigned') as segment

from source
