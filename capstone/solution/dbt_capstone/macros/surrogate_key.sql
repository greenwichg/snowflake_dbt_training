{#-
    Task 41 — surrogate key generation (custom implementation).
    Hashes one or more columns into a deterministic key; NULLs are made
    explicit so (NULL, 'a') and ('a', NULL) never collide.

    Usage: {{ surrogate_key(['sales_date']) }}
           {{ surrogate_key(['customer_id', 'order_month']) }}

    (dbt_utils.generate_surrogate_key does the same; the plan allows either.
     Writing it ourselves shows there's no magic: coalesce → concat → md5.)
-#}
{% macro surrogate_key(field_list) -%}
md5(
    {%- for field in field_list -%}
        coalesce(cast({{ field }} as varchar), '_dbt_null_')
        {%- if not loop.last %} || '|' || {% endif -%}
    {%- endfor -%}
)
{%- endmacro %}
