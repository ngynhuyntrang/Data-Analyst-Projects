SELECT *
FROM pizza_sales;

-- 1. Total revenue: 
SELECT SUM (total_price) as Total_Revenue
FROM pizza_sales;

-- 2. Average Order Value
SELECT  
	(SUM(total_price) / COUNT(distinct order_id)) as Avg_order_value
FROM pizza_sales;

-- 3. Total pizza sold
SELECT SUM(quantity) as Total_pizza_sold 
FROM pizza_sales;

-- 4. Total orders
SELECT COUNT(distinct order_id) as Total_orders
FROM pizza_sales;

-- 5. Average pizza order
SELECT CAST(CAST(SUM(quantity) as decimal(10, 2)) /
CAST(COUNT(distinct order_id) as decimal(10, 2)) as decimal (10, 2)) as Avg_Pizzas_per_order
FROM pizza_sales;

-- Hourly trend for pizzas sold
SELECT DATEPART(HOUR, order_time) AS order_hours, 
       SUM(quantity) AS total_pizzas_sold
FROM pizza_sales
GROUP BY DATEPART(HOUR, order_time)
ORDER BY DATEPART(HOUR, order_time);

-- Weekly trends for orders
SELECT 
    WEEK(STR_TO_DATE(order_date, '%d-%m-%Y'), 3) AS WeekNumber,
    YEAR(STR_TO_DATE(order_date, '%d-%m-%Y')) AS Year,
    COUNT(DISTINCT order_id) AS Total_orders
FROM 
    pizza_sales
GROUP BY 
    WeekNumber,
    Year
ORDER BY 
    Year, WeekNumber;
    
-- % of sales pizza category
SELECT pizza_category,
	CAST(SUM(total_price) as decimal (10, 2)) as total_revenue,
	CAST(SUM(total_price) * 100 / (SELECT SUM(total_price) from pizza_sales) as decimal (10, 2)) as pct
FROM pizza_sales
GROUP BY pizza_category;

-- % of sales by pizza size
SELECT pizza_size,
	CAST(SUM(total_price) as decimal (10, 2)) as total_revenue,
	CAST(SUM(total_price) * 100 / (SELECT SUM(total_price) FROM pizza_sales) as decimal (10, 2)) as pct
FROM pizza_sales
GROUP BY pizza_size
ORDER BY pizza_size;

-- % of sales by pizza size 'L'
WITH table_month AS (
  SELECT pizza_id, order_id, order_date, total_price
      , MONTH (order_date) AS [month]
      , YEAR (order_date) AS [year]
  FROM pizza_sales
  WHERE pizza_size = 'L'
)
, table_orders AS (
  SELECT DISTINCT [year], [month]
      , COUNT (order_id) OVER ( PARTITION BY [year], [month] ) AS number_large_order
  FROM table_month
)
SELECT *
  , SUM (number_large_order) OVER (PARTITION BY [year] ) AS total_trans_year
  , CAST ( number_large_order AS FLOAT ) * 100 / SUM (number_large_order) OVER (PARTITION BY [year] ) AS pct
FROM table_orders
ORDER BY [month] ASC;

-- Total pizzas sold by Pizza Category
SELECT pizza_category, 
    SUM(quantity) as Total_Quantity_Sold
FROM pizza_sales
GROUP BY pizza_category
ORDER BY Total_Quantity_Sold DESC;

-- Top 10 Pizza by Revenue
SELECT TOP 10 pizza_name,
    SUM(total_price) as Total_revenue
FROM pizza_sales
GROUP BY pizza_name
ORDER BY Total_revenue DESC;

-- Bottom 10 Pizza by Revenue 
SELECT TOP 10 pizza_name,
    SUM(total_price) as Total_revenue
FROM pizza_sales
GROUP BY pizza_name
ORDER BY Total_revenue ASC

-- Top 10 Pizza by Quantity
SELECT TOP 10 pizza_name,
    SUM(quantity) as Total_pizza_sold
FROM pizza_sales
GROUP BY pizza_name
ORDER BY Total_pizza_sold DESC

-- Bottom 10 Pizza by Quantity
SELECT TOP 10 pizza_name,
    SUM(quantity) as Total_pizza_sold
FROM pizza_sales
GROUP BY pizza_name
ORDER BY Total_pizza_sold ASC

-- Top 10 Pizza by Total orders
SELECT TOP 10 pizza_name,
    COUNT(DISTINCT order_id) as Total_orders
FROM pizza_sales
GROUP BY pizza_name
ORDER BY Total_orders DESC;

-- Bottom 10 Pizza by Total orders
SELECT TOP 10 pizza_name
    , COUNT(DISTINCT order_id) AS Total_Orders
FROM pizza_sales
WHERE pizza_category = 'Classic'
GROUP BY pizza_name
ORDER BY Total_Orders ASC;

-- Measure the retention of order in the twelve months of 2015 (Chicken) 
WITH table_cate AS (
    SELECT pizza_id, order_id, order_date, pizza_category
        , MIN (order_date) OVER (PARTITION BY pizza_id) AS first_time
        , DATEDIFF (month, MIN (order_date) OVER (PARTITION BY pizza_id), order_date) AS subsequent_month
    FROM pizza_sales
    WHERE pizza_category = 'Chicken'
)
, table_sub AS (
    SELECT MONTH (first_time) AS first_month, subsequent_month
        , COUNT (DISTINCT pizza_id) AS retained_pizza
    FROM table_cate
    GROUP BY MONTH (first_time), subsequent_month
)
SELECT *
    , FIRST_VALUE (retained_pizza) OVER ( ORDER BY subsequent_month ASC) AS original_pizza
    , CAST (retained_pizza AS FLOAT) * 100 / MAX (retained_pizza) OVER () AS pct 
FROM table_sub;
