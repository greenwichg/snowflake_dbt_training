{#-
    Custom GENERIC (schema) test — Day 4.
    Usable in any model's YAML like the built-in tests:

        columns:
          - name: amount_usd
            tests:
              - is_positive

    A test passes when its query returns zero rows.
-#}
{% test is_positive(model, column_name) %}

select {{ column_name }}
from {{ model }}
where {{ column_name }} is not null
  and {{ column_name }} <= 0

{% endtest %}
