-- Staging: flatten raw JSON VARIANT events into a typed relation
-- (the Day 1 Exercise 4 view, now managed by dbt).

with source as (

    select * from {{ source('raw', 'web_events_raw') }}

)

select
    event:event_id::string           as event_id,
    event:event_type::string         as event_type,
    event:timestamp::timestamp_ntz   as event_ts,
    event:user.customer_id::integer  as customer_id,
    event:user.device::string        as device,
    event:user.browser::string       as browser,
    event:page.url::string           as page_url,
    event:page.referrer::string      as referrer,
    event:order.order_id::integer    as order_id,
    event:order.amount::number(10,2) as order_amount,
    event:tags                       as tags,
    loaded_at

from source
