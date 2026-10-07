-- =====================================================
-- 01 BASIC ANALYSIS  (SELECT, GROUP BY, HAVING, JOIN)
-- =====================================================

-- Q1. Overall business KPIs
SELECT
    COUNT(DISTINCT order_id)                         AS total_orders,
    COUNT(DISTINCT customer_id)                      AS active_customers,
    ROUND(SUM(net_revenue), 0)                       AS total_revenue,
    ROUND(SUM(net_revenue - total_cost), 0)          AS total_profit,
    ROUND(100.0 * SUM(net_revenue - total_cost)
          / SUM(net_revenue), 1)                     AS profit_margin_pct,
    ROUND(SUM(net_revenue) / COUNT(DISTINCT order_id), 0) AS avg_order_value
FROM v_sales;

-- Q2. Revenue and profit by category
SELECT
    category,
    ROUND(SUM(net_revenue), 0)                AS revenue,
    ROUND(SUM(net_revenue - total_cost), 0)   AS profit,
    ROUND(100.0 * SUM(net_revenue - total_cost) / SUM(net_revenue), 1) AS margin_pct
FROM v_sales
GROUP BY category
ORDER BY revenue DESC;

-- Q3. Top 10 products by revenue
SELECT product_name, category,
       SUM(quantity)              AS units_sold,
       ROUND(SUM(net_revenue), 0) AS revenue
FROM v_sales
GROUP BY product_id, product_name, category
ORDER BY revenue DESC
LIMIT 10;

-- Q4. Revenue by state (top 8)
SELECT c.state,
       COUNT(DISTINCT s.order_id)  AS orders,
       ROUND(SUM(s.net_revenue),0) AS revenue
FROM v_sales s
JOIN customers c ON c.customer_id = s.customer_id
GROUP BY c.state
ORDER BY revenue DESC
LIMIT 8;

-- Q5. Payment method mix (share of orders)
SELECT payment_method,
       COUNT(DISTINCT order_id) AS orders,
       ROUND(100.0 * COUNT(DISTINCT order_id) /
             (SELECT COUNT(DISTINCT order_id) FROM v_sales), 1) AS pct_of_orders
FROM v_sales
GROUP BY payment_method
ORDER BY orders DESC;

-- Q6. Sub-categories with revenue above 150,000 (HAVING)
SELECT category, sub_category, ROUND(SUM(net_revenue),0) AS revenue
FROM v_sales
GROUP BY category, sub_category
HAVING SUM(net_revenue) > 150000
ORDER BY revenue DESC;

-- Q7. Order status breakdown (uses the raw orders table, including returns)
SELECT order_status,
       COUNT(*) AS orders,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM orders), 1) AS pct
FROM orders
GROUP BY order_status;
