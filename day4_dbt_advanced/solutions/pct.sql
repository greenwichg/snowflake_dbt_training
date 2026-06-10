{#-
    Solution: Day 4, Exercise 19.
    Safe percentage: returns NULL instead of erroring when the denominator
    is zero. Place in dbt_training/macros/pct.sql

    Usage: {{ pct('completed_orders', 'total_orders') }}
-#}
{% macro pct(numerator, denominator, precision=1) %}
    round(100.0 * ({{ numerator }}) / nullif({{ denominator }}, 0), {{ precision }})
{% endmacro %}
