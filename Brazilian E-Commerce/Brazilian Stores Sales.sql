CREATE DATABASE myprojectsql

SELECT *
FROM dbo.olist_customers

SELECT *
FROM dbo.olist_geolocation

SELECT *
FROM dbo.olist_order_items

SELECT *
FROM dbo.olist_order_payments

SELECT *
FROM dbo.olist_orders

SELECT *
FROM dbo.olist_products

SELECT *
FROM dbo.olist_sellers 

-- 1. Total sellers
SELECT COUNT(distinct seller_id) as Total_sellers
FROM olist_sellers 

-- 2. Total orders
SELECT COUNT(distinct order_id) as Total_orders
FROM olist_orders

-- 3. Total unique customers
SELECT COUNT(distinct customer_unique_id) as Total_unique_customers
FROM olist_customers

-- 4. Average order per seller 
SELECT (COUNT(order_id) / COUNT(distinct seller_id)) as Avg_payment_value
FROM olist_sellers AS sell
FULL JOIN olist_order_payments AS pay 
    ON sell.seller_id = pay.order_id

-- 5. Average Order Value 
SELECT (SUM(payment_value) / COUNT(distinct order_id)) as Avg_payment_value
FROM olist_order_payments

-- 6. Total value by payment type
SELECT payment_type
     , SUM (payment_value) as Total_value
FROM olist_order_payments
GROUP BY payment_type

-- 7. Total price in twelve months
WITH table_month AS (
  SELECT pro.product_id, order_id, shipping_limit_date, price, freight_value
      , MONTH (shipping_limit_date) AS [month]
      , YEAR (shipping_limit_date) AS [year]
  FROM olist_order_items AS item
  FULL JOIN olist_products AS pro
      ON item.product_id = pro.product_id
)
, table_orders AS (
  SELECT DISTINCT [year], [month]
      , COUNT (order_id) OVER ( PARTITION BY [year], [month] ) AS number_large_order
  FROM table_month
)
SELECT *
  , SUM (number_large_order) OVER (PARTITION BY [year] ) AS total_trans_year
FROM table_orders
ORDER BY [month] ASC;

-- 8. Checking number of customers depends on customer_city
SELECT customer_city
     , COUNT(customer_unique_id) AS number_customer 
FROM olist_customers AS cus
GROUP BY customer_city

-- Counting unique customers having processing order depends on customer_city
SELECT customer_city
     , COUNT(customer_unique_id) AS number_customer 
FROM olist_customers AS cus
LEFT JOIN olist_orders AS ord
    ON cus.customer_id = ord.customer_id
WHERE order_status = 'processing'
GROUP BY customer_city;

-- 9. Average payment value by Customer City
SELECT cus.customer_city 
    , payment_value / SUM(payment_value) as Average_payment_value
FROM olist_order_payments AS pay
FULL JOIN olist_orders AS ord
     ON pay.order_id = ord.order_id
FULL JOIN olist_customers AS cus
     ON pay.order_id = cus.customer_id
GROUP BY cus.customer_city 

-- 10. Average of price by Customer City 
SELECT cus.customer_city 
    , price / SUM(price) as Average_payment_value
FROM olist_order_payments AS pay
FULL JOIN olist_order_items AS item
     ON pay.order_id = item.order_id
FULL JOIN olist_customers AS cus
     ON pay.order_id = cus.customer_id
GROUP BY cus.customer_city 

-- 11. Top 5 orders by product category
SELECT TOP 5 product_category_name 
     , COUNT(product_id) AS number_of_products 
FROM dbo.olist_orders AS ord 
FULL JOIN dbo.olist_products AS pro
      ON ord.order_id = pro.product_id
WHERE product_category_name IS NOT NULL
GROUP BY product_category_name 
ORDER BY product_category_name DESC

-- 12. Bottom 5 orders by product category
SELECT TOP 5 product_category_name 
     , COUNT(product_id) AS number_of_products 
FROM dbo.olist_orders AS ord 
FULL JOIN dbo.olist_products AS pro
      ON ord.order_id = pro.product_id
WHERE product_category_name IS NOT NULL
GROUP BY product_category_name 
ORDER BY product_category_name ASC

-- Selecting orders delivered in 2017
SELECT order_id
      , order_status
      , order_delivered_customer_date
FROM olist_orders
WHERE order_delivered_customer_date BETWEEN '2017-01-01 00:00:00' AND '2017-12-31 23:59:59'

-- Selecting orders approved by Olist in 2017
SELECT * 
FROM olist_orders
WHERE order_purchase_timestamp BETWEEN '2017-01-01 00:00:00' AND '2017-12-31 23:59:59'

-- Selecting orders approved by Olist in 2018
SELECT * 
FROM olist_orders
WHERE order_purchase_timestamp BETWEEN '2018-01-01 00:00:00' AND '2018-12-31 23:59:59'

--SELECT COUNT(order_status) AS shipped
FROM olist_orders
WHERE order_status = 'shipped';

--SELECT COUNT(order_status) AS invoiced
FROM olist_orders
WHERE order_status = 'invoiced';

--SELECT COUNT(order_status) AS processing
FROM olist_orders
WHERE order_status = 'processing';

--SELECT COUNT(order_status) AS approved
FROM olist_orders
WHERE order_status = 'approved';

-- Counting order status
WITH table_range AS (
    SELECT *
      , CASE WHEN order_status = 'delivered' THEN 'delivered_order'
      WHEN order_status = 'shipped' THEN 'shipped_order'
      WHEN order_status = 'invoiced' THEN 'invoiced_order'
      WHEN order_status = 'processing' THEN 'processing_order'
      ELSE 'approve_order'
      END AS range_status
    FROM dbo.olist_orders
)
SELECT range_status
     , COUNT(order_id) AS number_order
FROM table_range 
GROUP BY range_status 

-- Counting delivered order of customers
SELECT customer_id
     , COUNT ( CASE WHEN order_status = 'delivered' THEN 'order_id' END) AS number_delivered_order
FROM olist_orders AS ord
FULL JOIN olist_products AS pro
    ON ord.order_id = pro.product_id 
LEFT JOIN olist_order_items AS item
    ON ord.order_id = item.order_id
GROUP BY customer_id

-- % of order products category
SELECT payment_type
    , SUM(payment_value) as total_revenue
	, SUM(payment_value) * 100 / (SELECT SUM(payment_value) from olist_order_payments) as pct
FROM olist_products AS pro
FULL JOIN olist_order_payments AS pay
    ON pro.product_id = pay.order_id
WHERE payment_type IS NOT NULL
GROUP BY payment_type;

-- Selecting payments made by "credit_card" 
SELECT order_id
    , payment_type
    , payment_value
FROM olist_order_payments
WHERE payment_type = 'credit_card';

-- The trend of the number of successful payment transactions with promotion (promtion_trans) on a weekly basis and account for how much of the total number of successful payment transactions (promotion_ratio)
With table_trans AS (
   SELECT DATEPART(WEEK, shipping_limit_date) AS [week]
       , COUNT(payment_value) AS num_value
       , SUM(payment_value) AS total_value
   FROM olist_order_items AS item
   JOIN olist_order_payments AS pay
          ON item.order_id = pay.order_id
      WHERE payment_type = 'credit_card'
   GROUP BY DATEPART(WEEK, shipping_limit_date)
)
SELECT *
   , (num_value * 100 / SUM(num_value) OVER (PARTITION BY [week])) AS pct
FROM table_trans

-- Percentage of ordered products
WITH table_count AS (
    SELECT product_category_name 
     , COUNT(item.order_id) AS number_orders
    FROM olist_order_items AS item
    FULL JOIN olist_products AS pro
    ON item.product_id = pro.product_id 
    GROUP BY product_category_name
)
SELECT *
    , (number_orders * 100 / SUM(number_orders) OVER ()) AS pct_order
FROM table_count

-- Caculate RFM of orders
WITH table_rfm AS (
    SELECT customer_id
        , DATEDIFF (day, MAX (order_purchase_timestamp), '2017-12-31') AS recency
        , COUNT (DISTINCT CAST (order_purchase_timestamp AS DATE)) AS frequency 
        , SUM (payment_value) AS monetary
    FROM olist_orders AS ord
    FULL JOIN olist_products AS pro
        ON pro.product_id = ord.order_id
    FULL JOIN olist_order_payments AS pay
        ON ord.order_id = pay.order_id
    GROUP BY customer_id
)
, table_rank AS (
    SELECT *
        , CAST (PERCENT_RANK() OVER (ORDER BY recency ASC) AS DECIMAL (10,2)) AS r_rank
        , CAST (PERCENT_RANK() OVER (ORDER BY frequency ASC) AS DECIMAL (10,2)) AS f_rank
        , CAST (PERCENT_RANK() OVER (ORDER BY monetary ASC) AS DECIMAL (10,2)) AS m_rank
    FROM table_rfm
)
, table_tier AS (
    SELECT *
        , CASE WHEN r_rank < 0.25 THEN 1
            WHEN r_rank < 0.5 THEN 2
            WHEN r_rank < 0.75 THEN 3
            ELSE 4 END AS r_tier 
        , CASE WHEN f_rank < 0.25 THEN 1
            WHEN f_rank < 0.5 THEN 2
            WHEN f_rank < 0.75 THEN 3
            ELSE 4 END AS f_tier 
        , CASE WHEN m_rank < 0.25 THEN 1
            WHEN m_rank < 0.5 THEN 2
            WHEN m_rank < 0.75 THEN 3
            ELSE 4 END AS m_tier 
    FROM table_rank
)
, table_score AS (
   SELECT *
       , CONCAT (r_tier,f_tier,m_tier) AS rfm_score
   FROM table_tier
)
--------------- Segment following logic of score
SELECT *
  , CASE
    WHEN rfm_score = 111 THEN 'Best Customers'
    WHEN rfm_score LIKE '[3-4][3-4][1-4]' THEN 'Lost Bad Customer' 
    WHEN rfm_score LIKE '[3-4]2[1-4]' THEN 'Lost Customers'
    WHEN rfm_score LIKE '21[1-4]' THEN 'Almost Lost'
    WHEN rfm_score LIKE '11[2-4]' THEN 'Loyal Customers'
    WHEN rfm_score LIKE '[1-2][1-3]1' THEN 'Big Spenders' 
    WHEN rfm_score LIKE '[1-2]4[1-4]' THEN 'New Customers' 
    WHEN rfm_score LIKE '[3-4]1[1-4]' THEN 'Hibernating' 
    WHEN rfm_score LIKE '[1-2][2-3][2-4]' THEN 'Potential Loyalists' 
    ELSE 'unknown' END AS segment
FROM table_score



