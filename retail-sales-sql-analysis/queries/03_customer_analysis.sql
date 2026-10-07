-- =====================================================
-- 03 CUSTOMER ANALYSIS  (RANK, NTILE, RFM, cohorts, retention)
-- =====================================================

-- Q14. Top 10 customers by lifetime revenue
SELECT c.customer_id, c.customer_name, c.city,
       COUNT(DISTINCT s.order_id)  AS orders,
       ROUND(SUM(s.net_revenue),0) AS lifetime_revenue
FROM v_sales s
JOIN customers c ON c.customer_id = s.customer_id
GROUP BY c.customer_id, c.customer_name, c.city
ORDER BY lifetime_revenue DESC
LIMIT 10;

-- Q15. Pareto check: what share of revenue comes from the top 20% of customers?
WITH cust AS (
    SELECT customer_id, SUM(net_revenue) AS revenue
    FROM v_sales GROUP BY customer_id
),
ranked AS (
    SELECT customer_id, revenue,
           NTILE(5) OVER (ORDER BY revenue DESC) AS quintile
    FROM cust
)
SELECT quintile,
       COUNT(*)                                         AS customers,
       ROUND(SUM(revenue), 0)                           AS revenue,
       ROUND(100.0 * SUM(revenue) / (SELECT SUM(revenue) FROM cust), 1) AS pct_of_revenue
FROM ranked
GROUP BY quintile
ORDER BY quintile;

-- Q16. Top-selling product in each category (RANK with PARTITION BY)
WITH product_rev AS (
    SELECT category, product_name, SUM(net_revenue) AS revenue
    FROM v_sales
    GROUP BY category, product_name
),
ranked AS (
    SELECT *, RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rnk
    FROM product_rev
)
SELECT category, product_name, ROUND(revenue,0) AS revenue
FROM ranked
WHERE rnk = 1
ORDER BY revenue DESC;

-- Q17. RFM segmentation
WITH rfm_base AS (
    SELECT customer_id,
           CAST(julianday((SELECT MAX(order_date) FROM v_sales)) - julianday(MAX(order_date)) AS INT) AS recency_days,
           COUNT(DISTINCT order_id) AS frequency,
           SUM(net_revenue)         AS monetary
    FROM v_sales
    GROUP BY customer_id
),
scored AS (
    SELECT *,
           NTILE(4) OVER (ORDER BY recency_days DESC) AS r_score,   -- 4 = most recent
           NTILE(4) OVER (ORDER BY frequency)         AS f_score,
           NTILE(4) OVER (ORDER BY monetary)          AS m_score
    FROM rfm_base
)
SELECT
    CASE
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 2                   THEN 'Loyal / Potential'
        WHEN r_score <= 2 AND f_score >= 3                   THEN 'At Risk'
        WHEN r_score = 1  AND f_score = 1                    THEN 'Lost'
        ELSE 'Needs Attention'
    END AS segment,
    COUNT(*)                 AS customers,
    ROUND(AVG(monetary), 0)  AS avg_revenue,
    ROUND(AVG(frequency), 1) AS avg_orders
FROM scored
GROUP BY segment
ORDER BY avg_revenue DESC;

-- Q18. New vs returning customers per year
WITH first_order AS (
    SELECT customer_id, MIN(order_date) AS first_date
    FROM v_sales GROUP BY customer_id
)
SELECT s.order_year,
       COUNT(DISTINCT CASE WHEN SUBSTR(f.first_date,1,4) = s.order_year THEN s.customer_id END) AS new_customers,
       COUNT(DISTINCT CASE WHEN SUBSTR(f.first_date,1,4) < s.order_year THEN s.customer_id END) AS returning_customers
FROM v_sales s
JOIN first_order f ON f.customer_id = s.customer_id
GROUP BY s.order_year
ORDER BY s.order_year;

-- Q19. Repeat purchase rate
WITH cust_orders AS (
    SELECT customer_id, COUNT(DISTINCT order_id) AS orders
    FROM v_sales GROUP BY customer_id
)
SELECT
    COUNT(*)                                            AS total_customers,
    SUM(CASE WHEN orders > 1 THEN 1 ELSE 0 END)         AS repeat_customers,
    ROUND(100.0 * SUM(CASE WHEN orders > 1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS repeat_rate_pct
FROM cust_orders;

-- Q20. Cohort retention: signup-year cohorts and the % still ordering in each later year
WITH cohort AS (
    SELECT customer_id, SUBSTR(signup_date,1,4) AS cohort_year FROM customers
),
activity AS (
    SELECT DISTINCT customer_id, order_year FROM v_sales
)
SELECT c.cohort_year,
       a.order_year,
       COUNT(DISTINCT a.customer_id) AS active_customers,
       ROUND(100.0 * COUNT(DISTINCT a.customer_id) /
             (SELECT COUNT(*) FROM cohort c2 WHERE c2.cohort_year = c.cohort_year), 1) AS pct_of_cohort
FROM cohort c
JOIN activity a ON a.customer_id = c.customer_id
WHERE a.order_year >= c.cohort_year
GROUP BY c.cohort_year, a.order_year
ORDER BY c.cohort_year, a.order_year;
