-- Create database
CREATE DATABASE amazon_db;

USE amazon_db;

-- Create table with correct column types
CREATE TABLE amazon_products (
product_id            VARCHAR(20),
product_name          VARCHAR(600),
category              VARCHAR(200),
discounted_price      DECIMAL(10,2),
actual_price          DECIMAL(10,2),
discount_percentage   DECIMAL(5,2),
rating                DECIMAL(3,1),
rating_count          INT,
about_product         TEXT,
user_id               VARCHAR(300),
user_name             VARCHAR(200),
review_id             VARCHAR(150),
review_title          VARCHAR(500),
review_content        LONGTEXT,
img_link              VARCHAR(300),
product_link          VARCHAR(300)
);

-- Import csv
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/amazon_fixed.csv'
INTO TABLE amazon_products
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 1. Database Overview
-- Total number of products
SELECT COUNT(*) AS total_products FROM amazon_products;

-- Total number of categories
 SELECT count(DISTINCT category) AS total_categories FROM amazon_products;
 
-- Overall average rating
SELECT round(avg(rating), 2) AS avg_rating FROM amazon_products;

-- 2. Category Analysis
-- Total products per category
SELECT 
    category,
    COUNT(*) AS total_products
FROM amazon_products
GROUP BY category
ORDER BY total_products DESC;

-- Average rating per category
SELECT 
    category,
    ROUND(AVG(rating), 2) AS avg_rating,
    COUNT(*) AS total_products
FROM amazon_products
GROUP BY category
ORDER BY avg_rating DESC;

-- 3. Price Anaysis
-- Most expensive and cheepest products
SELECT
    Product_name,
    actual_price,
    discounted_price
FROM amazon_products
ORDER BY actual_price DESC
LIMIT 10;

-- Average discount percentage per category
SELECT
    category,
    ROUND(AVG(discount_percentage) * 100, 2) AS avg_discount_pct
FROM amazon_products
GROUP BY category
ORDER BY avg_discount_pct DESC;

-- Product with more than 70% discount
SELECT 
     product_name,
     actual_price,
     discounted_price,
     ROUND(discount_percentage * 100,2)AS discount_pct
FROM amazon_products
WHERE discount_percentage  >= 0.70
ORDER BY discount_percentage DESC;

-- 4. Rating Analysis
-- Top 10 highest rated products with most reviews
SELECT 
    product_name,
    rating,
    rating_count
FROM amazon_products
WHERE rating_count > 1000
ORDER BY rating DESC, rating_count DESC
LIMIT 10;

-- Rating distribution (how many products per rating group)
SELECT 
    CASE 
        WHEN rating >= 4.5 THEN 'Excellent (4.5-5.0)'
        WHEN rating >= 4.0 THEN 'Good (4.0-4.4)'
        WHEN rating >= 3.0 THEN 'Average (3.0-3.9)'
        ELSE 'Poor (below 3.0)'
    END AS rating_group,
    COUNT(*) AS total_products
FROM amazon_products
GROUP BY rating_group
ORDER BY total_products DESC;

-- 5. Product performance
-- Best value products (high rating + high discount)
SELECT 
    product_name,
    rating,
    ROUND(discount_percentage * 100, 2) AS discount_pct,
    discounted_price
FROM amazon_products
WHERE rating >= 4.0 
AND discount_percentage >= 0.50
ORDER BY discount_pct DESC, rating DESC
LIMIT 10;

-- Most reviewed products (popularity)
SELECT 
    product_name,
    rating_count,
    rating,
    discounted_price
FROM amazon_products
ORDER BY rating_count DESC
LIMIT 10;

-- 6. Windows Function
-- Rank products by rating within each category
SELECT 
    product_name,
    category,
    rating,
    RANK() OVER(PARTITION BY category ORDER BY rating DESC) AS rank_in_category
FROM amazon_products;

-- Top 3 products per category by rating
WITH ranked AS (
    SELECT 
        product_name,
        category,
        rating,
        rating_count,
        RANK() OVER(PARTITION BY category ORDER BY rating DESC) AS rnk
    FROM amazon_products
)
SELECT * FROM ranked
WHERE rnk <= 3;

-- Running total of products by category
SELECT 
    category,
    COUNT(*) AS products_in_category,
    SUM(COUNT(*)) OVER(ORDER BY category) AS running_total
FROM amazon_products
GROUP BY category;

-- Price difference from category average
SELECT 
    product_name,
    category,
    discounted_price,
    ROUND(AVG(discounted_price) OVER(PARTITION BY category), 2) AS category_avg_price,
    ROUND(discounted_price - AVG(discounted_price) OVER(PARTITION BY category), 2) AS diff_from_avg
FROM amazon_products
ORDER BY category;

-- 7. CTE Queries
-- Find categories where average discount is above overall average
WITH overall_avg AS (
    SELECT AVG(discount_percentage) AS avg_discount
    FROM amazon_products
),
category_avg AS (
    SELECT 
        category,
        ROUND(AVG(discount_percentage) * 100, 2) AS cat_avg_discount
    FROM amazon_products
    GROUP BY category
)
SELECT 
    c.category,
    c.cat_avg_discount,
    ROUND(o.avg_discount * 100, 2) AS overall_avg_discount
FROM category_avg c
CROSS JOIN overall_avg o
WHERE c.cat_avg_discount > o.avg_discount * 100
ORDER BY c.cat_avg_discount DESC;

-- Products priced below category average (good deals)
WITH category_avg AS (
    SELECT 
        category,
        AVG(discounted_price) AS avg_price
    FROM amazon_products
    GROUP BY category
)
SELECT 
    p.product_name,
    p.category,
    p.discounted_price,
    ROUND(c.avg_price, 2) AS category_avg_price
FROM amazon_products p
JOIN category_avg c ON p.category = c.category
WHERE p.discounted_price < c.avg_price
ORDER BY p.category;

-- 8 Executive Summary
-- Full business summary in one query
SELECT 
    COUNT(*) AS total_products,
    COUNT(DISTINCT category) AS total_categories,
    ROUND(AVG(rating), 2) AS avg_rating,
    MAX(rating) AS highest_rating,
    MIN(rating) AS lowest_rating,
    ROUND(AVG(discount_percentage) * 100, 2) AS avg_discount_pct,
    MAX(actual_price) AS most_expensive,
    MIN(discounted_price) AS cheapest,
    SUM(rating_count) AS total_reviews
FROM amazon_products;
