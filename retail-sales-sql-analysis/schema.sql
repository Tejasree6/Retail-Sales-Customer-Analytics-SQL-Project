-- =====================================================
-- Retail Sales & Customer Analytics: Database Schema
-- Dialect: SQLite (works with minor edits in MySQL/PostgreSQL)
-- =====================================================

DROP VIEW IF EXISTS v_sales;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id   INTEGER PRIMARY KEY,
    customer_name TEXT NOT NULL,
    city          TEXT NOT NULL,
    state         TEXT NOT NULL,
    segment       TEXT NOT NULL,      -- Consumer / Corporate / Small Business
    signup_date   TEXT NOT NULL       -- YYYY-MM-DD
);
use sql_project1;

CREATE TABLE products (
    product_id   INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category     TEXT NOT NULL,
    sub_category TEXT NOT NULL,
    unit_cost    REAL NOT NULL,
    unit_price   REAL NOT NULL
);

CREATE TABLE orders (
    order_id       INTEGER PRIMARY KEY,
    customer_id    INTEGER NOT NULL REFERENCES customers(customer_id),
    order_date     TEXT NOT NULL,     -- YYYY-MM-DD
    ship_date      TEXT NOT NULL,
    order_status   TEXT NOT NULL,     -- Delivered / Returned / Cancelled
    payment_method TEXT NOT NULL      -- UPI / Card / COD / NetBanking
);

CREATE TABLE order_items (
    order_item_id INTEGER PRIMARY KEY,
    order_id      INTEGER NOT NULL REFERENCES orders(order_id),
    product_id    INTEGER NOT NULL REFERENCES products(product_id),
    quantity      INTEGER NOT NULL,
    unit_price    REAL NOT NULL,
    discount_pct  REAL NOT NULL       -- 0 to 0.30
);

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date     ON orders(order_date);
CREATE INDEX idx_items_order     ON order_items(order_id);
CREATE INDEX idx_items_product   ON order_items(product_id);

-- Reusable view: one row per sold line item, valid sales only
-- (Cancelled and Returned orders are excluded from revenue)
GO
CREATE VIEW v_sales AS
SELECT
    oi.order_item_id,
    o.order_id,
    o.customer_id,
    o.order_date,
    SUBSTR(o.order_date, 1, 7)  AS order_month,      -- YYYY-MM
    SUBSTR(o.order_date, 1, 4)  AS order_year,
    o.payment_method,
    p.product_id,
    p.product_name,
    p.category,
    p.sub_category,
    oi.quantity,
    ROUND(oi.quantity * oi.unit_price * (1 - oi.discount_pct), 2) AS net_revenue,
    ROUND(oi.quantity * p.unit_cost, 2)                           AS total_cost
FROM order_items oi
JOIN orders   o ON o.order_id   = oi.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status = 'Delivered';
