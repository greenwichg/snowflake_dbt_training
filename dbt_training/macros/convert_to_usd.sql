{#-
    Converts an amount column to USD using the fx_rates seed.
    Usage: {{ convert_to_usd('source.amount', 'source.currency') }}

    IMPORTANT: pass TABLE-QUALIFIED columns (e.g. 'source.currency', not
    'currency'). Inside the lookup subquery an unqualified `currency` would
    resolve to fx.currency itself — always true, returning every seed row.

    Falls back to the original amount if the currency is missing from the seed.
-#}
{% macro convert_to_usd(amount_column, currency_column) %}
    round(
        {{ amount_column }} * coalesce(
            (select fx.usd_rate
             from {{ ref('fx_rates') }} fx
             where fx.currency = {{ currency_column }}),
            1.0
        ),
        2
    )
{% endmacro %}
