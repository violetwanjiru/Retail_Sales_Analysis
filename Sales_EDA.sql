/*
===============================================================================
Project: Business Insights and Sales Analysis - SQL Script
===============================================================================
Description:
    This SQL script performs a comprehensive analysis on a retail sales database.
    It is designed to provide insights into customer behavior, product performance,
    and overall business metrics. The script is structured into multiple sections
    covering data exploration, key performance indicators (KPIs), trend analysis,
    and customer segmentation.

Script Sections:
-------------------------------------------------------------------------------
1. Database Exploration
    -- Explore tables, columns, and metadata.

2. Dimension Insights
    -- Analyze distinct values in customer countries and product categories.

3. Sales Overview
    -- Compute total sales, quantity, orders, and price metrics.

4. Customer Demographics
    -- Identify age extremes, total customers, and order participation.

5. Key Business Metrics Summary
    -- Aggregate all main KPIs into a single unified report.

6. Magnitude Analysis
    -- Breakdown of customer and product distributions by category, country, etc.

7. Revenue and Sales Analysis
    -- Evaluate revenue by category, product, and customer.

8. Sales Trends Over Time
    -- Annual sales changes and cumulative sales tracking.

9. Product Performance Evaluation
    -- Identify top-performing and worst-performing products.

10. Year-over-Year Product Comparison
    -- Compare current vs. previous years and vs. product average sales.

11. Category Contribution Analysis
    -- Measure each category’s contribution to overall sales.

12. Product Cost Segmentation
    -- Group products into price segments for cost distribution.

13. Customer Segmentation
    -- Classify customers into VIP, Regular, and New based on behavior.

*/

-- Explore All objects in the database
SELECT *
FROM INFORMATION_SCHEMA.TABLES;

-- Explore All columns in the database
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS;

-- Explore all countries our customers from.
SELECT DISTINCT country
FROM gold.dim_customers;

-- Explore All categories "The major divisions"
Select DISTINCT category, subcategory, product_name FROM gold.dim_products
ORDER BY 1,2,3;

-- Find the date of the first and last order
-- How many years of sales available

SELECT MIN(order_date) AS first_date,
MAX(order_date) AS last_date,
DATEDIFF(year, MIN(order_date), MAX(order_date)) AS order_range_years
FROM gold.fact_sales;

-- Find the youngest and the oldest customer
SELECT
MIN(birthdate) AS Oldest,
DATEDIFF(year, MIN(birthdate), GETDATE()) AS oldest_age,
DATEDIFF(year, MAX(birthdate), GETDATE()) AS oldest_age
FROM gold.dim_customers;

-- Find the Total Sales

SELECT SUM(sales_amount) AS total_sales
FROM gold.fact_sales;

-- Find how many items are sold
SELECT SUM(quantity) AS total_quantity
FROM gold.fact_sales;

-- Find the average selling price

SELECT AVG(price) AS avg_price
FROM gold.fact_sales;

-- Find the Total number of Orders

SELECT COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales;

-- Find the total number of products
SELECT COUNT(product_name) AS total_products
FROM gold.dim_products;

-- Find the total number of customers
SELECT COUNT(customer_key) AS total_key
FROM gold.dim_customers;

-- Find the total number of customers that has placed an order
SELECT COUNT(DISTINCT customer_key) AS total_customers
FROM gold.fact_sales;

-- Generate a Report that shows all key metrics of the business
SELECT 'Total Sales' as Measure_name, SUM(sales_amount) AS Measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity', SUM(quantity) FROM gold.fact_sales
UNION ALL
SELECT 'Average Price', AVG(price) FROM gold.fact_sales
UNION ALL
SELECT 'Total Nr. Orders', COUNT(DISTINCT order_number) FROM gold.fact_sales
UNION ALL
SELECT 'Total Nr. Products', COUNT(product_name) FROM gold.dim_products
UNION ALL
SELECT 'Total Nr. Customers', COUNT (customer_key) FROM gold.dim_customers

-- Magnitude Analysis
-- Find total customers by countries
SELECT
country,
COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;

-- Find total customers by gender
SELECT
gender,
COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;

-- Find total products by category
SELECT
category,
COUNT(product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;

-- What is the average costs in each category?
SELECT
category,
AVG(cost) AS avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost DESC;

-- What is the total revenue generated for each category?
SELECT 
p.category,
SUM(sales_amount) AS total_revenue
FROM gold.fact_sales as s
LEFT JOIN gold.dim_products AS p
ON p.product_key = s.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;
-- Find total revenue is generated by each customer
SELECT 
c.customer_key,
c.first_name,
c.last_name,
SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
ON c.customer_key = f.customer_key
GROUP BY 
c.customer_key,
c.first_name,
c.last_name
ORDER BY total_revenue DESC;

-- What is the distribution of sold items across countries?
SELECT 
c.country,
SUM(f.quantity) as total_sold_items
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
ON c.customer_key = f.customer_key
GROUP BY c.country
ORDER BY total_sold_items DESC;



-- Which products generate the highest revenue
SELECT *
FROM (
	SELECT 
		p.product_name,
		SUM(s.sales_amount) AS total_revenue,
		ROW_NUMBER() OVER(ORDER BY SUM(s.sales_amount) DESC) AS rank_products
	FROM gold.fact_sales AS s
	LEFT JOIN gold.dim_products AS p
		ON p.product_key = s.product_key
	GROUP BY p.product_name
) t
WHERE rank_products <= 5

-- What are the 5 worst performing products in terms of sales.
SELECT TOP 5
p.product_name,
SUM(sales_amount) AS total_revenue
FROM gold.fact_sales as s
LEFT JOIN gold.dim_products AS p
ON p.product_key = s.product_key
GROUP BY p.product_name
ORDER BY total_revenue ;

-- Change over time analysis - trends
SELECT
YEAR(order_date) AS order_year,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date);


-- Cumulative Analysis
-- Calculate the total sales per month and the running total of sales over time
SELECT
    order_date,
    total_sales,
    SUM(total_sales) OVER (ORDER BY order_date) AS running_total_sales,
	AVG(avg_price) OVER (ORDER BY order_date) AS moving_avg_price
FROM
(
    SELECT
        DATETRUNC(year, order_date) AS order_date,
        SUM(sales_amount) AS total_sales,
		AVG(price) AS avg_price
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(year, order_date)
) t;

/* Analyse the yearly performance of products by comparing each products sales 
to both its average sales performance and previous years sales */
WITH yearly_product_sales AS (
SELECT 
YEAR(f.order_date) AS order_year,
p.product_name,
SUM(f.sales_amount) AS current_sales
FROM gold.fact_sales as f
LEFT JOIN gold.dim_products as p
ON f.product_key = p.product_key
WHERE order_date IS NOT NULL
GROUP BY YEAR(f.order_date),
p.product_name) 
SELECT 
order_year,
product_name,
current_sales,
AVG(current_sales) OVER(PARTITION BY product_name) as avg_sales,
current_sales - AVG(current_sales) OVER(PARTITION BY product_name) AS diff_avg,
CASE WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) > 0 THEN 'Above avg'
	 WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) < 0 THEN 'Below avg'
	 ELSE 'Avg'
END AS avg_change,
LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS previous_year,
current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) as diff_prev_yr,
CASE WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
	 WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
	 ELSE 'No change'
END AS prev_yr_change
FROM yearly_product_sales
ORDER BY product_name, order_year;


-- Which categories contribute the most to overall sales
WITH category_sales AS (
    SELECT 
        p.category,
        SUM(f.sales_amount) AS total_sales
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_products AS p
        ON f.product_key = p.product_key
    GROUP BY p.category
)

SELECT 
    category,
    total_sales,
    SUM(total_sales) OVER () AS overall_sales,
    CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER ()) * 100, 2), '%') AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC;

-- segment products into cost ranges and count how many products fall into each segment
WITH product_segments AS(
SELECT 
product_key,
product_name,
cost,
CASE WHEN cost < 100 THEN 'Below 100'
	 WHEN cost BETWEEN 101 AND 500 THEN '101-500'
	 WHEN cost BETWEEN 501 AND 1000 THEN '501 - 1000'
	 ELSE 'Above 1000'
END AS cost_range
FROM gold.dim_products)

SELECT 
cost_range,
COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC;

/*Group customers into three segments based on their spending behavior:
       - VIP: Customers with at least 12 months of history and spending more than €5,000.
       - Regular: Customers with at least 12 months of history but spending €5,000 or less
       - New: Customers with a lifespan less than 12 months.
And find the total number of customers by each group
*/
WITH customer_spending AS (
SELECT 
c.customer_key,
SUM(sales_amount) AS total_spending,
MIN(order_date) AS first_order,
MAX(order_date) AS last_order,
DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key)

SELECT
    customer_segment,
    COUNT(customer_key) AS total_customers
FROM (
    SELECT
        customer_key,
        CASE WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
             WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
             ELSE 'New'
        END customer_segment
    FROM customer_spending
) t
GROUP BY customer_segment
ORDER BY total_customers;
