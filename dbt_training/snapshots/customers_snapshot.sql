{#-
    Day 4 lab: SCD Type 2 history of the raw customers table.
    Change a customer's country in RAW.CUSTOMERS, re-run `dbt snapshot`,
    and observe dbt_valid_from / dbt_valid_to.
-#}
{% snapshot customers_snapshot %}

{{
    config(
        schema='snapshots',
        unique_key='customer_id',
        strategy='check',
        check_cols=['email', 'country', 'is_active'],
    )
}}

select
    customer_id,
    first_name,
    last_name,
    email,
    country,
    is_active

from {{ source('raw', 'customers') }}

{% endsnapshot %}
