{#-
    Converts an amount column to USD using the fx_rates seed.
    Usage: {{ convert_to_usd('amount', 'currency') }}
    Falls back to the original amount if the currency is missing from the seed.
-#}
{% macro convert_to_usd(amount_column, currency_column) %}
    round(
        {{ amount_column }} * coalesce(
            (select usd_rate
             from {{ ref('fx_rates') }} fx
             where fx.currency = {{ currency_column }}),
            1.0
        ),
        2
    )
{% endmacro %}
