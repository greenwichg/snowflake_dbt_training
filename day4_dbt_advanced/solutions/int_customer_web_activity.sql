-- Solution: Day 4, Exercise 20 — per-customer web activity.
-- Place in dbt_training/models/intermediate/int_customer_web_activity.sql
-- (folder default = ephemeral: inlined as a CTE, never built in Snowflake)

with events as (

    select * from {{ ref('stg_web_events') }}
    where customer_id is not null    -- anonymous events can't join to a customer

)

select
    customer_id,
    count(*)                                                as web_events,
    count(case when event_type = 'page_view' then 1 end)    as web_page_views,
    count(case when event_type = 'purchase'  then 1 end)    as web_purchases,
    min(event_ts)                                           as first_seen_at,
    max(event_ts)                                           as last_seen_at

from events
group by customer_id
