-- Portfolio Analysis for Brazilian_ecommerce_dataset
-- Major Business Question : 
# Step 1 : Data Understanding
# Step 2 : Data Validation & Cleaning if needed
# Step 3 : Analytical Dataset / Views
# Step 4 : Exploratory Data Analysis
# Step 5 : Business Findings
# Step 6 : Power BI Visualization

-- STEP 1.1 Figuring out if customer_id and customer_unique_id are unique or not
-- I chose windows functions here because i want to see each the original table still
WITH CTE_customer_unique_check AS
(
SELECT customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state,
ROW_NUMBER()OVER(PARTITION BY customer_id) AS customer_id_check,
ROW_NUMBER()OVER(PARTITION BY customer_unique_id) AS customer_unique_id_check
FROM olist_customers_dataset
)
SELECT customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state,
CASE ## this two cases are here just to simplify when we see the table, because the customer_id is very hard to read
	WHEN customer_id_check > 1 THEN 'NOT UNIQUE'
    ELSE 'UNIQUE'
END AS customer_id_final_check,
CASE
	WHEN customer_unique_id_check > 1 THEN 'NOT UNIQUE'
    ELSE 'UNIQUE'
END AS customer_unique_id_final_check
FROM CTE_customer_unique_check
WHERE customer_id_check > 1
	OR customer_unique_id_check > 1
;

-- The result is customer_id uniquely identifies the customer record associated with an order.
-- customer_unique_id can occur multiple times, representing the same underlying customer across multiple customer_id records.

SELECT 
    *
FROM
    olist_order_items_dataset
;

WITH CTE_orderid_check AS
(
SELECT order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value,
ROW_NUMBER()OVER(PARTITION BY order_id) AS order_id_unique_check
FROM olist_order_items_dataset
)
SELECT order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value,
CASE WHEN order_id_unique_check > 1 THEN 'NOT UNIQUE' ELSE 'UNIQUE' ## help make it legible
END AS 'order_id_final_check'
FROM CTE_orderid_check
;

-- The result is order_id is NOT unique because a single order can contain multiple line items (tracked sequentially by order_item_id)

-- Step 1.3 check if an order have multiple payment rows
WITH CTE_multiple_payment_check AS
(
SELECT order_id, payment_sequential, payment_type, payment_installments, payment_value,
ROW_NUMBER()OVER(PARTITION BY order_id) AS order_id_duplicate_check
FROM olist_order_payments_dataset
)
SELECT order_id, payment_sequential, payment_type, payment_installments, payment_value,
CASE 
	WHEN order_id_duplicate_check > 1 THEN 'NOT UNIQUE' ELSE 'UNIQUE'
END AS order_id_uniquefinalcheck
FROM CTE_Multiple_payment_check
WHERE order_id_duplicate_check > 1
ORDER BY order_id, payment_sequential
;
-- One order can have multiple payment records, distinguished by payment_sequential

-- Step 1.4 check if there are multiple reviews per order
WITH CTE_duplicate_check AS
(
SELECT review_id, order_id, review_score, review_creation_date, review_answer_timestamp,
ROW_NUMBER()OVER(PARTITION BY review_id) AS review_id_unique_check,
ROW_NUMBER()OVER(PARTITION BY order_id) AS order_id_unique_check
FROM olist_order_reviews_dataset
)
SELECT review_id, order_id, review_score, review_creation_date, review_answer_timestamp,
CASE WHEN review_id_unique_check > 1 THEN 'NOT UNIQUE' ELSE 'UNIQUE'
END AS review_id_final_check ,
CASE WHEN order_id_unique_check > 1 THEN ' NOT UNIQUE' ELSE 'UNIQUE'
END AS order_id_final_check
FROM CTE_duplicate_check
WHERE review_id_unique_check > 1
	OR order_id_unique_check > 1
ORDER BY order_id ;

-- Result is one order can have multiple reviews

SELECT 
    *
FROM
    olist_orders_dataset
;

WITH CTE_orders_unique_check AS
(
SELECT order_id, customer_id, order_status,
ROW_NUMBER()OVER(PARTITION BY order_id) AS order_id_duplicate_check
FROM olist_orders_dataset
)
SELECT order_id, customer_id, order_status,
CASE WHEN order_id_duplicate_check > 1 THEN 'NOT UNIQUE' ELSE 'UNIQUE'
END AS order_id_final_check
FROM CTE_orders_unique_check
WHERE order_id_duplicate_check > 1
ORDER BY order_id
;

-- The results are unique orders, so one row equals one order, it does not state which items are bought though
-- Step 1.6 check NULL values in important columns

SELECT 
    *
FROM
    olist_customers_dataset
WHERE
    customer_id IS NULL
        OR customer_unique_id IS NULL
;
-- no null values
-- olist_order_items_dataset
SELECT 
    *
FROM
    olist_order_items_dataset
WHERE
    order_id IS NULL OR product_id IS NULL
        OR seller_id IS NULL
        OR price IS NULL
        OR freight_value IS NULL
;
-- no null values
-- olist_order_payments_dataset
SELECT 
    *
FROM
    olist_order_payments_dataset
WHERE
    order_ID IS NULL
        OR payment_sequential IS NULL
        OR payment_type IS NULL
        OR payment_installments IS NULL
        OR payment_value IS NULL
;
-- no null values but there are 0 values, somehow the payment value 0 is possible
-- olist_order_reviews_dataset

SELECT 
    *
FROM
    olist_order_reviews_dataset
WHERE
    review_id IS NULL OR order_id IS NULL
        OR review_score IS NULL
;

-- No null values
-- olist_orders_dataset

SELECT 
    *
FROM
    olist_orders_dataset
WHERE
    order_id IS NULL OR customer_id IS NULL
        OR order_status IS NULL
;

-- No null values
-- olist_products_dataset

SELECT 
    *
FROM
    olist_products_dataset
WHERE
    product_id IS NULL
        OR product_category_name IS NULL
;

-- No null values
-- olist_sellers_dataset

SELECT 
    *
FROM
    olist_sellers_dataset
WHERE
    seller_id IS NULL
        OR seller_zip_code_prefix IS NULL
        OR seller_city IS NULL
        OR seller_state IS NULL
;

-- Step 2 : Data validation & cleaning if needed
-- Datetime check for each table (when needed)
-- olist_customers_dataset, only needed a check NULL or blank values done in the previous step
SELECT 
    *
FROM
    olist_customers_dataset
;
-- olist_order_items_dataset, check price and freight_value is not negative or impossible numbers

SELECT 
    *
FROM
    olist_order_items_dataset
WHERE
    price <= 0 OR freight_value <= 0
ORDER BY price DESC
;
-- No non-positive prices were identified. Zero freight values were retained because free shipping is plausible.

SELECT 
    *
FROM
    olist_order_payments_dataset
WHERE
    payment_value <= 0
        OR payment_installments <= 0
        OR payment_sequential <= 0
;

-- There is one payment installment 0 and multiple payment_value 0, and very high sequentials such as 24

UPDATE olist_order_reviews_dataset 
SET 
    review_creation_date = CASE
        WHEN TRIM(review_creation_date) = '' THEN NULL
        WHEN review_creation_date LIKE '%/%' THEN STR_TO_DATE(review_creation_date, '%m/%d/%Y %H:%i')
        ELSE STR_TO_DATE(review_creation_date,
                '%Y-%m-%d %H:%i:%s')
    END,
    review_answer_timestamp = CASE
        WHEN TRIM(review_answer_timestamp) = '' THEN NULL
        WHEN
            review_answer_timestamp LIKE '%/%'
        THEN
            STR_TO_DATE(review_answer_timestamp,
                    '%m/%d/%Y %H:%i')
        ELSE STR_TO_DATE(review_answer_timestamp,
                '%Y-%m-%d %H:%i:%s')
    END;

ALTER TABLE olist_order_reviews_dataset
	MODIFY COLUMN review_creation_date DATETIME,
    MODIFY COLUMN review_answer_timestamp DATETIME;

-- olist_orders_dataset check is order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date
-- is date time or not, after checking MYSQL table schema it is text so we UPDATE below

SELECT 
    *
FROM
    olist_orders_dataset;

UPDATE olist_orders_dataset 
SET 
    order_purchase_timestamp = CASE
        WHEN TRIM(order_purchase_timestamp) = '' THEN NULL
        ELSE STR_TO_DATE(order_purchase_timestamp,
                '%Y-%m-%d %H:%i:%s')
    END,
    order_approved_at = CASE
        WHEN TRIM(order_approved_at) = '' THEN NULL
        ELSE STR_TO_DATE(order_approved_at, '%Y-%m-%d %H:%i:%s')
    END,
    order_delivered_carrier_date = CASE
        WHEN TRIM(order_delivered_carrier_date) = '' THEN NULL
        ELSE STR_TO_DATE(order_delivered_carrier_date,
                '%Y-%m-%d %H:%i:%s')
    END,
    order_delivered_customer_date = CASE
        WHEN TRIM(order_delivered_customer_date) = '' THEN NULL
        ELSE STR_TO_DATE(order_delivered_customer_date,
                '%Y-%m-%d %H:%i:%s')
    END,
    order_estimated_delivery_date = CASE
        WHEN TRIM(order_estimated_delivery_date) = '' THEN NULL
        ELSE STR_TO_DATE(order_estimated_delivery_date,
                '%Y-%m-%d %H:%i:%s')
    END;

ALTER TABLE olist_orders_dataset
    MODIFY COLUMN order_purchase_timestamp DATETIME,
    MODIFY COLUMN order_approved_at DATETIME,
    MODIFY COLUMN order_delivered_carrier_date DATETIME,
    MODIFY COLUMN order_delivered_customer_date DATETIME,
    MODIFY COLUMN order_estimated_delivery_date DATETIME;

-- olist_products_dataset, olist_seller_dataset, and product_category_name_translation has nothing to change
SELECT 
    *
FROM
    olist_products_dataset
WHERE
    product_id IS NULL
        OR product_category_name IS NULL
        OR product_id = ' '
        OR product_category_name = ' '
;

SELECT 
    *
FROM
    olist_sellers_dataset
WHERE
    seller_id IS NULL OR seller_id = ' '
        OR seller_zip_code_prefix IS NULL
        OR seller_zip_code_prefix = ' '
        OR seller_city IS NULL
        OR seller_city = ' '
        OR seller_state IS NULL
        OR seller_state = ' '
;

SELECT 
    *
FROM
    product_category_name_translation
WHERE
    ï»¿product_category_name IS NULL
        OR product_category_name_english IS NULL;

-- After further examination, the data is clean after data cleaning step above.

-- Step 3 : Data analytic view, where we join tables and create a new table to refer to for the rest of the project
## Foundational Business Question to answer : What factors are assosciated with poor customer experience in Olist m=arketplace?
## i created a foundation table where 1 row = 1 order to query off of

CREATE TEMPORARY TABLE customer_experience_foundation
WITH aggregated_reviews AS
(
SELECT order_id, AVG(review_score) AS order_avg_review
FROM olist_order_reviews_dataset
GROUP BY order_id
)
SELECT orders.order_id, 
orders.customer_id, 
customers.customer_unique_id, 
order_status, 
order_purchase_timestamp, 
order_delivered_customer_date, 
order_estimated_delivery_date,
order_avg_review
FROM olist_orders_dataset AS orders
LEFT JOIN aggregated_reviews AS reviews
	ON orders.order_id = reviews.order_id
LEFT JOIN olist_customers_dataset AS customers
	ON orders.customer_id = customers.customer_id
;

-- STEP 4 : EDA, lets figure out whether orders with late delivery is assosciated with lower review scores
-- Final grain we're looking for : one row = review score, no_of_orders, no_of_late_orders, pct_late_orders

SELECT 
    CASE
        WHEN order_avg_review >= 4.5 THEN 5
        WHEN order_avg_review >= 3.5 THEN 4
        WHEN order_avg_review >= 2.5 THEN 3
        WHEN order_avg_review >= 1.5 THEN 2
        WHEN order_avg_review >= 0.5 THEN 1
    END AS avg_review,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT CASE
            WHEN
                DATEDIFF(order_estimated_delivery_date,
                        order_delivered_customer_date) < 0
            THEN
                order_id
        END) AS late_orders,
    ROUND((COUNT(DISTINCT CASE
                    WHEN
                        DATEDIFF(order_estimated_delivery_date,
                                order_delivered_customer_date) < 0
                    THEN
                        order_id
                END) * 100.0) / COUNT(DISTINCT order_id),
            2) AS pct_late_orders
FROM
    customer_experience_foundation
WHERE
    order_avg_review IS NOT NULL
        AND order_delivered_customer_date IS NOT NULL
GROUP BY avg_review
ORDER BY avg_review DESC
;
-- Lower review scores are strongly associated with higher rates of late delivery.
-- The late-order rate increases monotonically from 1.86% among 5-star orders to 36.78% among 1-star orders.
-- Our next step is whether these late deliveries are connected to destination (customer geography)
-- Our final grain is : customer state, total orders, late orders, pct late orders, avg_review

SELECT 
    customer_state,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(COUNT(DISTINCT CASE
                    WHEN
                        DATEDIFF(order_estimated_delivery_date,
                                order_delivered_customer_date) < 0
                    THEN
                        order_id
                END)) AS late_orders,
    ROUND(COUNT(DISTINCT CASE
                    WHEN
                        DATEDIFF(order_estimated_delivery_date,
                                order_delivered_customer_date) < 0
                    THEN
                        order_id
                END) * 100.0 / COUNT(DISTINCT order_id),
            2) AS pct_late_orders,
    AVG(order_avg_review) AS avg_review_score
FROM
    customer_experience_foundation AS CEF
        LEFT JOIN
    olist_customers_dataset AS customers ON CEF.customer_id = customers.customer_id
WHERE order_delivered_customer_date IS NOT NULL
AND order_avg_review IS NOT NULL
GROUP BY customer_state
ORDER BY pct_late_orders DESC , avg_review_score DESC
;

-- Customer states with higher late-delivery rates generally also show lower average review scores, 
-- suggesting that delivery reliability and customer experience vary geographically.
-- The next question is, whether these late deliveries are concentrated on certain sellers?
-- BUT we have to create a different temporary table, due to seller_id resides in the olist_order_items_dataset, where grain is item -> orders
-- Lets make that first

CREATE TEMPORARY TABLE seller_order_foundation
WITH items AS
(
SELECT DISTINCT order_id, seller_id
FROM olist_order_items_dataset
),
aggregated_reviews AS
(
SELECT order_id, AVG(review_score) AS order_avg_review
FROM olist_order_reviews_dataset
GROUP BY order_id
)
SELECT items.order_id, items.seller_id,
orders.order_estimated_delivery_date, orders.order_delivered_customer_date,
order_avg_review
FROM items
LEFT JOIN aggregated_reviews AS reviews
	ON items.order_id = reviews.order_id
LEFT JOIN olist_orders_dataset AS orders
	ON items.order_id = orders.order_id
WHERE orders.order_delivered_customer_date IS NOT NULL
AND reviews.order_avg_review IS NOT NULL
ORDER BY order_id
;

-- Now,  The next question is, whether these late deliveries are concentrated on certain sellers?
-- Our final grain we're looking for is : sellers, total_orders, late_orders, pct_late_orders, avg_review_scor

SELECT seller_id, COUNT(DISTINCT order_id) AS total_orders,
COUNT(CASE WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) < 0 THEN order_id END) AS late_orders,
ROUND(COUNT(CASE WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) < 0 THEN order_id END) * 100.0 / COUNT(DISTINCT order_Id),2) AS pct_late_orders,
ROUND(AVG(order_avg_review),2) AS avg_review
FROM seller_order_foundation
WHERE order_avg_review IS NOT NULL
GROUP BY seller_id
HAVING COUNT(DISTINCT order_id) >= 50
ORDER BY pct_late_orders DESC, avg_review ASC
;

-- Certain sellers have higher late-order rates and tend to have lower average review scores
-- We picked at minimum 50 here to reduce instability because lower quantity sellers have smaller samples
-- Now the next question is whether multi seller orders are assosciated with different delivery/review outcomes vs single orders
-- The final grain we're looking for is = one row one type of seller, with total_orders, avg(days_ahead_of_estimate), pct_late_delivery, avg_review
WITH order_unique_count AS
(
SELECT order_id, 
COUNT(DISTINCT seller_id) AS unique_sellers,
MAX(DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date)) AS date_differential,
MAX(order_avg_review) AS order_review
FROM seller_order_foundation
WHERE seller_id IS NOT NULL
GROUP BY order_id
)
SELECT 
CASE WHEN unique_sellers > 1 THEN 'Multi'
	ELSE 'single'
END AS order_type, 
COUNT(DISTINCT order_id) AS total_orders, 
COUNT(DISTINCT CASE WHEN date_differential < 0 THEN order_id END) AS late_orders,
ROUND(AVG(date_differential),2) AS avg_days_ahead,
ROUND(AVG(order_review),2) AS avg_review,
ROUND(COUNT(CASE WHEN date_differential < 0 THEN order_id END),2) * 100.0 / COUNT(DISTINCT order_id) AS pct_late_orders
FROM order_unique_count
GROUP BY CASE WHEN unique_sellers > 1 THEN 'Multi'
	ELSE 'single'
END
;

-- Multi-seller orders have substantially lower average review scores despite having lower late-delivery rates 
-- and a higher average delivery lead over the estimated date

-- Creating a view for PowerBI exports

## customer_experience_foundation
CREATE OR REPLACE VIEW customer_experience_foundation AS
WITH aggregated_reviews AS
(
SELECT order_id, AVG(review_score) AS order_avg_review
FROM olist_order_reviews_dataset
GROUP BY order_id
)
SELECT orders.order_id, 
orders.customer_id, 
customers.customer_unique_id, 
order_status, 
order_purchase_timestamp, 
order_delivered_customer_date, 
order_estimated_delivery_date,
order_avg_review
FROM olist_orders_dataset AS orders
LEFT JOIN aggregated_reviews AS reviews
	ON orders.order_id = reviews.order_id
LEFT JOIN olist_customers_dataset AS customers
	ON orders.customer_id = customers.customer_id
;

##seller_order_foundation
CREATE OR REPLACE VIEW seller_order_foundation AS
WITH items AS
(
SELECT DISTINCT order_id, seller_id
FROM olist_order_items_dataset
),
aggregated_reviews AS
(
SELECT order_id, AVG(review_score) AS order_avg_review
FROM olist_order_reviews_dataset
GROUP BY order_id
)
SELECT items.order_id, items.seller_id,
orders.order_estimated_delivery_date, orders.order_delivered_customer_date,
order_avg_review
FROM items
LEFT JOIN aggregated_reviews AS reviews
	ON items.order_id = reviews.order_id
LEFT JOIN olist_orders_dataset AS orders
	ON items.order_id = orders.order_id
WHERE orders.order_delivered_customer_date IS NOT NULL
AND reviews.order_avg_review IS NOT NULL
ORDER BY order_id
;

SELECT Database();