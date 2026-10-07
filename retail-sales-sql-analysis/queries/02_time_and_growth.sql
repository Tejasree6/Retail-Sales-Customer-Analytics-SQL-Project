-- =====================================================
-- 02 TIME-BASED ANALYSIS  (CTEs, window functions: LAG, running totals)
-- =====================================================

-- Q8. Monthly revenue trend
SELECT order_month, ROUND(SUM(net_revenue),0) AS revenue
FROM v_sales
GROUP BY order_month
ORDER BY order_month;

-- Q9. Month-over-month growth % using LAG
WITH monthly AS (
    SELECT order_month, SUM(net_revenue) AS revenue
    FROM v_sales
    GROUP BY order_month
)
SELECT order_month,
       ROUND(revenue, 0) AS revenue,
       ROUND(LAG(revenue) OVER (ORDER BY order_month), 0) AS prev_month,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY order_month))
             / LAG(revenue) OVER (ORDER BY order_month), 1) AS mom_growth_pct
FROM monthly
ORDER BY order_month;

-- Q10. Year-over-year comparison by category
WITH yearly AS (
    SELECT category, order_year, SUM(net_revenue) AS revenue
    FROM v_sales
    GROUP BY category, order_year
)
SELECT category, order_year,
       ROUND(revenue, 0) AS revenue,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (PARTITION BY category ORDER BY order_year))
             / LAG(revenue) OVER (PARTITION BY category ORDER BY order_year), 1) AS yoy_growth_pct
FROM yearly
ORDER BY category, order_year;

-- Q11. Running (cumulative) revenue
WITH monthly AS (
    SELECT order_month, SUM(net_revenue) AS revenue
    FROM v_sales GROUP BY order_month
)
SELECT order_month,
       ROUND(revenue, 0) AS revenue,
       ROUND(SUM(revenue) OVER (ORDER BY order_month), 0) AS cumulative_revenue
FROM monthly
ORDER BY order_month;

-- Q12. 3-month moving average of revenue
WITH monthly AS (
    SELECT order_month, SUM(net_revenue) AS revenue
    FROM v_sales GROUP BY order_month
)
SELECT order_month,
       ROUND(revenue, 0) AS revenue,
       ROUND(AVG(revenue) OVER (ORDER BY order_month
             ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 0) AS moving_avg_3m
FROM monthly
ORDER BY order_month;

-- Q13. Festive-season effect: Oct-Nov vs rest of the year
SELECT order_year,
       ROUND(SUM(CASE WHEN SUBSTR(order_month,6,2) IN ('10','11') THEN net_revenue END), 0) AS festive_revenue,
       ROUND(SUM(CASE WHEN SUBSTR(order_month,6,2) NOT IN ('10','11') THEN net_revenue END), 0) AS other_revenue,
       ROUND(100.0 * SUM(CASE WHEN SUBSTR(order_month,6,2) IN ('10','11') THEN net_revenue END)
             / SUM(net_revenue), 1) AS festive_share_pct
FROM v_sales
GROUP BY order_year
ORDER BY order_year;
