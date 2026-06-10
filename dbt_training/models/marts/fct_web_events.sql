-- Mart: incremental event fact (Day 4 lab).
-- First run builds everything; later runs insert only events newer than
-- what's already in the table.

{{
    config(
        materialized='incremental',
        unique_key='event_id',
        on_schema_change='append_new_columns'
    )
}}

select
    event_id,
    event_type,
    event_ts,
    customer_id,
    device,
    browser,
    page_url,
    referrer,
    order_id,
    order_amount

from {{ ref('stg_web_events') }}

{% if is_incremental() %}
  -- only process events newer than the latest already loaded
  where event_ts > (select coalesce(max(event_ts), '1900-01-01') from {{ this }})
{% endif %}
