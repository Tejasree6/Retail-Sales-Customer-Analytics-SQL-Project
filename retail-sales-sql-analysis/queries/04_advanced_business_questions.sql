-- =====================================================
-- 04 ADVANCED BUSINESS QUESTIONS  (subqueries, CASE, self-joins, data quality)
-- =====================================================

-- Q21. Which categories are above the average category revenue? (subquery)
WITH cat AS (
    SELECT category, SUM(net_revenue) AS revenue FROM v_sales GROUP BY category
)
SELECT category, ROUND(revenue,0) AS revenue
FROM cat
WHERE revenue > (SELECT AVG(revenue) FROM cat)
ORDER BY revenue DESC;

-- Q22. Does a bigger discount hurt margin? Profit margin by discount band
SELECT
    CASE WHEN oi.discount_pct = 0    THEN '0%'
         WHEN oi.discount_pct <= 0.10 THEN '1-10%'
         WHEN oi.discount_pct <= 0.20 THEN '11-20%'
         ELSE '21-30%' END AS discount_band,
    COUNT(*) AS line_items,
    ROUND(SUM(oi.quantity*oi.unit_price*(1-oi.discount_pct)), 0) AS revenue,
    ROUND(100.0 * (SUM(oi.quantity*oi.unit_price*(1-oi.discount_pct)) - SUM(oi.quantity*p.unit_cost))
          / SUM(oi.quantity*oi.unit_price*(1-oi.discount_pct)), 1) AS margin_pct
FROM order_items oi
JOIN orders   o ON o.order_id = oi.order_id AND o.order_status = 'Delivered'
JOIN products p ON p.product_id = oi.product_id
GROUP BY discount_band
ORDER BY MIN(oi.discount_pct);

-- Q23. Return rate by category (uses all orders, not just delivered)
SELECT p.category,
       COUNT(DISTINCT o.order_id) AS orders,
       COUNT(DISTINCT CASE WHEN o.order_status='Returned' THEN o.order_id END) AS returned,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN o.order_status='Returned' THEN o.order_id END)
             / COUNT(DISTINCT o.order_id), 1) AS return_rate_pct
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p     ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY return_rate_pct DESC;

-- Q24. Average shipping time (days) by state
SELECT c.state,
       ROUND(AVG(julianday(o.ship_date) - julianday(o.order_date)), 2) AS avg_ship_days,
       COUNT(*) AS orders
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY c.state
HAVING COUNT(*) >= 50
ORDER BY avg_ship_days DESC;

-- Q25. Market-basket: product pairs most often bought together (self-join)
SELECT a.product_name AS product_a,
       b.product_name AS product_b,
       COUNT(*)       AS times_together
FROM v_sales a
JOIN v_sales b
  ON a.order_id = b.order_id
 AND a.product_id < b.product_id
GROUP BY a.product_id, b.product_id, a.product_name, b.product_name
ORDER BY times_together DESC
LIMIT 10;

-- Q26. Customers who signed up but never placed a valid order
SELECT COUNT(*) AS never_purchased
FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM v_sales s WHERE s.customer_id = c.customer_id);

-- Q27. Best month per year (window function + filter)
WITH monthly AS (
    SELECT order_year, order_month, SUM(net_revenue) AS revenue
    FROM v_sales GROUP BY order_year, order_month
),
ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY order_year ORDER BY revenue DESC) AS rn
    FROM monthly
)
SELECT order_year, order_month, ROUND(revenue,0) AS revenue
FROM ranked WHERE rn = 1
ORDER BY order_year;

-- Q28. Data quality checks (always include these in a real project)
SELECT 'Orders with no items' AS check_name, COUNT(*) AS issues
FROM orders o WHERE NOT EXISTS (SELECT 1 FROM order_items oi WHERE oi.order_id = o.order_id)
UNION ALL
SELECT 'Ship date before order date', COUNT(*) FROM orders WHERE ship_date < order_date
UNION ALL
SELECT 'Orders placed before customer signup', COUNT(*)
FROM orders o JOIN customers c ON c.customer_id = o.customer_id WHERE o.order_date < c.signup_date
UNION ALL
SELECT 'Items with price below product cost', COUNT(*)
FROM order_items oi JOIN products p ON p.product_id = oi.product_id
WHERE oi.unit_price * (1 - oi.discount_pct) < p.unit_cost;
