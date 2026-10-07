# Retail Sales & Customer Analytics: SQL Project

End-to-end SQL analysis of an Indian e-commerce business: **28 queries** covering sales performance, growth trends, customer segmentation (RFM), cohort retention, discount impact and data-quality checks.

> **Data note:** The dataset is **synthetic**, generated with a fixed random seed (`generate_data.py`) so anyone can reproduce the results. The schema and queries work unchanged on real data. Load your own CSVs into the same four tables.

---

## Business Questions Answered
1. How is the business performing overall (revenue, profit, margin, AOV)?
2. Which categories, products and states drive revenue and profit?
3. How does revenue grow month over month and year over year? Is there a festive-season effect?
4. Who are the best customers, and how concentrated is revenue among them?
5. Which customers are loyal, at risk or lost? (RFM segmentation)
6. Do customers come back? (repeat rate, cohort retention)
7. Do discounts hurt profitability?
8. Which categories have the highest return rates?

## Database Schema

```
customers (500)      orders (2,789)         order_items (4,703)     products (36)
-------------        --------------         ------------------      -------------
customer_id  PK <--- customer_id  FK        order_item_id PK        product_id PK
customer_name        order_id     PK <----- order_id      FK        product_name
city, state          order_date             product_id    FK -----> category, sub_category
segment              ship_date              quantity                unit_cost
signup_date          order_status           unit_price              unit_price
                     payment_method         discount_pct
```

A reusable view, `v_sales`, holds delivered line items only (cancelled and returned orders are excluded) with `net_revenue = quantity x price x (1 - discount)` and `total_cost`.

## Project Structure

```
retail-sales-sql-analysis/
|-- README.md
|-- schema.sql                          # tables, indexes, v_sales view
|-- generate_data.py                    # builds retail.db + CSVs (seed = 42)
|-- run_all.py                          # runs every query and prints results
|-- retail.db                           # ready-to-use SQLite database
|-- data/                               # CSV copies of all 4 tables
`-- queries/
    |-- 01_basic_analysis.sql           # Q1-Q7
    |-- 02_time_and_growth.sql          # Q8-Q13
    |-- 03_customer_analysis.sql        # Q14-Q20
    `-- 04_advanced_business_questions.sql  # Q21-Q28
```

## How to Run

```bash
python generate_data.py        # creates retail.db
python run_all.py              # runs all 28 queries
# or open retail.db in DB Browser for SQLite / DBeaver and run queries individually
```

## SQL Skills Demonstrated

| Skill | Where |
|---|---|
| Joins (inner, self-join), subqueries, `EXISTS` | Q4, Q25, Q26 |
| `GROUP BY`, `HAVING`, `CASE WHEN` | Q2, Q6, Q13, Q22 |
| CTEs | Q9-Q12, Q15-Q20 |
| Window functions: `LAG`, `RANK`, `ROW_NUMBER`, `NTILE`, running totals, moving average | Q9-Q12, Q15-Q17, Q27 |
| Views | `v_sales` |
| RFM segmentation, cohort retention, Pareto analysis | Q15, Q17, Q20 |
| Market-basket analysis | Q25 |
| Data-quality validation | Q28 |

## Key Findings (from this dataset)

| Metric | Result |
|---|---|
| Revenue / profit | **₹1.62 Cr revenue, ₹65.4 L profit (40.4% margin)** from 2,437 delivered orders |
| Average order value | ₹6,642 |
| Category concentration | **Electronics = 71% of revenue** but the lowest margin (33% vs 55-62% elsewhere) |
| Single-product dependence | Laptops alone bring in ₹60 L, about 37% of total revenue |
| Customer concentration | **Top 20% of customers generate 64.5% of revenue**; the bottom 20% generate 1% |
| Discounts | Margin falls from **44.6% (no discount) to 16.6% (21-30% discount)** |
| Returns | Highest in Beauty & Health (8.5%) and Books & Stationery (8.0%) |
| Retention | **79.7% repeat purchase rate**; 2022 cohort still 68% active in 2024 |
| Seasonality | Oct-Nov contribute 31-37% of yearly revenue; best month each year is Oct or Nov |
| Geography | Maharashtra is the top state (₹47.6 L); UPI is 45.5% of orders |

## Recommendations
1. **Reduce dependence on Electronics/Laptops** by growing higher-margin categories (Fashion, Beauty, Home & Kitchen).
2. **Cap discounts at about 20%**. Beyond that, margin drops sharply.
3. **Run retention campaigns for "At Risk" customers** (RFM segment). They have high past value but low recent activity.
4. **Plan inventory and marketing ahead of Oct-Nov**, which is the peak season.
5. **Investigate return reasons** for Beauty & Health and Books.

## Next Steps
- Build a Power BI dashboard on top of these tables (KPIs, category/state breakdown, RFM segments, cohort heatmap).
- Port the queries to PostgreSQL or MySQL (`julianday` becomes date subtraction, `SUBSTR` becomes `TO_CHAR`/`DATE_TRUNC`).

**Tech:** SQLite · Python 3 (data generation only) · standard SQL
