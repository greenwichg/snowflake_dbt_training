--------------------------------------------------------------------------------
-- Day 1 / Exercise 6 — Snowflake SQL refresher: complex analytical queries
-- Uses the CUSTOMERS and ORDERS tables loaded in Exercise 3.
--------------------------------------------------------------------------------
USE ROLE SYSADMIN;
USE WAREHOUSE TRAINING_WH;
USE SCHEMA TRAINING_DB.RAW;

--------------------------------------------------------------------------------
-- 1. Joins + aggregation: revenue per country (completed orders only)
--------------------------------------------------------------------------------
SELECT
    c.COUNTRY,
    COUNT(DISTINCT c.CUSTOMER_ID) AS customers,
    COUNT(o.ORDER_ID)             AS orders,
    SUM(o.AMOUNT)                 AS revenue,
    ROUND(AVG(o.AMOUNT), 2)       AS avg_order_value
FROM CUSTOMERS c
LEFT JOIN ORDERS o
       ON o.CUSTOMER_ID = c.CUSTOMER_ID
      AND o.STATUS = 'completed'
GROUP BY c.COUNTRY
ORDER BY revenue DESC NULLS LAST;

--------------------------------------------------------------------------------
-- 2. CTEs: month-over-month revenue with growth %
--------------------------------------------------------------------------------
WITH monthly AS (
    SELECT DATE_TRUNC('month', ORDER_DATE) AS month,
           SUM(AMOUNT)                     AS revenue
    FROM ORDERS
    WHERE STATUS = 'completed'
    GROUP BY 1
)
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month)                              AS prev_month,
    ROUND(100 * (revenue - prev_month) / NULLIF(prev_month, 0), 1)  AS growth_pct
FROM monthly
ORDER BY month;

--------------------------------------------------------------------------------
-- 3. Window functions: each customer's order sequence and running spend
--------------------------------------------------------------------------------
SELECT
    CUSTOMER_ID,
    ORDER_ID,
    ORDER_DATE,
    AMOUNT,
    ROW_NUMBER() OVER (PARTITION BY CUSTOMER_ID ORDER BY ORDER_DATE)            AS order_seq,
    SUM(AMOUNT)  OVER (PARTITION BY CUSTOMER_ID ORDER BY ORDER_DATE
                       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)        AS running_spend,
    DATEDIFF('day',
             LAG(ORDER_DATE) OVER (PARTITION BY CUSTOMER_ID ORDER BY ORDER_DATE),
             ORDER_DATE)                                                        AS days_since_prev
FROM ORDERS
WHERE STATUS = 'completed'
ORDER BY CUSTOMER_ID, order_seq;

--------------------------------------------------------------------------------
-- 4. Ranking: top spender per country (QUALIFY = filter on window result)
--------------------------------------------------------------------------------
SELECT
    c.COUNTRY,
    c.FIRST_NAME || ' ' || c.LAST_NAME AS customer,
    SUM(o.AMOUNT)                      AS total_spend,
    RANK() OVER (PARTITION BY c.COUNTRY ORDER BY SUM(o.AMOUNT) DESC) AS rnk
FROM CUSTOMERS c
JOIN ORDERS o ON o.CUSTOMER_ID = c.CUSTOMER_ID AND o.STATUS = 'completed'
GROUP BY c.COUNTRY, customer
QUALIFY rnk = 1
ORDER BY total_spend DESC;

--------------------------------------------------------------------------------
-- 5. Conditional aggregation (pivot-style)
--------------------------------------------------------------------------------
SELECT
    DATE_TRUNC('month', ORDER_DATE)                            AS month,
    COUNT_IF(STATUS = 'completed')                             AS completed,
    COUNT_IF(STATUS = 'cancelled')                             AS cancelled,
    COUNT_IF(STATUS = 'refunded')                              AS refunded,
    SUM(IFF(STATUS = 'completed', AMOUNT, 0))                  AS net_revenue
FROM ORDERS
GROUP BY 1
ORDER BY 1;

--------------------------------------------------------------------------------
-- 6. Cohorts: revenue by signup month of the customer
--------------------------------------------------------------------------------
WITH cohorts AS (
    SELECT CUSTOMER_ID, DATE_TRUNC('month', SIGNUP_DATE) AS cohort_month
    FROM CUSTOMERS
)
SELECT
    ch.cohort_month,
    COUNT(DISTINCT ch.CUSTOMER_ID)  AS cohort_size,
    COUNT(o.ORDER_ID)               AS orders,
    COALESCE(SUM(o.AMOUNT), 0)      AS revenue
FROM cohorts ch
LEFT JOIN ORDERS o ON o.CUSTOMER_ID = ch.CUSTOMER_ID AND o.STATUS = 'completed'
GROUP BY ch.cohort_month
ORDER BY ch.cohort_month;

--------------------------------------------------------------------------------
-- 7. Challenge exercises (write these yourself)
--------------------------------------------------------------------------------
-- a) Customers who have never placed a completed order (anti-join: NOT EXISTS).
-- b) For each customer, the percentage of their lifetime spend that came from
--    their single largest order (window MAX over SUM).
-- c) A "repeat rate": of customers with >=1 completed order, what % have >=2?
-- d) Using ANALYTICS.WEB_EVENTS (Exercise 4): conversion rate from page_view
--    to purchase by device type.
--------------------------------------------------------------------------------
