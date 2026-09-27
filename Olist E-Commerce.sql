USE [Brazilian E-Commerce];

--What is the overall total sales (total revenue)?

SELECT SUM(OI.price) AS total_sales
FROM olist_order_items_dataset OI;


-- What is the monthly sales trend over time?

SELECT
YEAR(O.order_purchase_timestamp) AS order_year,
MONTH(O.order_purchase_timestamp) AS order_month,
SUM(OI.price) AS total_sales
FROM olist_orders_dataset O
INNER JOIN olist_order_items_dataset OI
ON O.order_id = OI.order_id
GROUP BY YEAR(O.order_purchase_timestamp),MONTH(O.order_purchase_timestamp)
ORDER BY order_year,order_month;


-- What are the top products categories by total sales and 
--How does their average selling price compare?

SELECT TOP 10
OC.product_category_name_english AS product_category,
ROUND(SUM(OI.price), 2) AS total_sales,
ROUND(AVG(OI.price), 2) AS avg_selling_price
FROM olist_products_dataset P
LEFT JOIN Olist_order_items_dataset OI
ON P.product_id = OI.product_id
LEFT JOIN olist_order_category_dataset OC
ON OC.product_category_name = P.product_category_name
GROUP BY OC.product_category_name_english
ORDER BY total_sales desc;


-- What are the top cities and states by total sales?

SELECT TOP 10 C.customer_city,C.customer_state,
ROUND(SUM(OI.price), 2) AS total_sales,
COUNT(DISTINCT OI.order_id) AS total_orders,
ROUND(AVG(OI.price), 2) AS avg_selling_price
FROM olist_order_items_dataset OI
INNER JOIN olist_orders_dataset O ON OI.order_id = O.order_id
INNER JOIN olist_customers_dataset C ON O.customer_id = C.customer_id
GROUP BY C.customer_city,C.customer_state
ORDER BY total_sales desc;


--What are the top seller cities and states by total sales?

SELECT TOP 10
    S.seller_city, S.seller_state,
    ROUND(SUM(OI.price), 2) AS total_sales,
    COUNT(DISTINCT OI.order_id) AS total_orders,
    ROUND(AVG(OI.price), 2) AS avg_selling_price
FROM olist_sellers_dataset S
JOIN olist_order_items_dataset OI ON S.seller_id = OI.seller_id
GROUP BY 
    S.seller_city,
    S.seller_state
ORDER BY 
    total_sales DESC;


--What is the total number of unique customers and average order price distributed by city and state?

SELECT C.customer_city, C.customer_state,
COUNT(DISTINCT C.customer_unique_id) AS total_customers,
ROUND(AVG(OI.price), 2) AS avg_selling_price
FROM olist_customers_dataset C
JOIN olist_orders_dataset O ON O.customer_id = C.customer_id
JOIN olist_order_items_dataset OI ON O.order_id = OI.order_id
GROUP BY C.customer_city,C.customer_state
ORDER BY total_customers DESC;


--Who are the top 10 customers based on total sales and order frequency?

SELECT TOP 10 C.customer_unique_id,
ROUND(SUM(OI.price), 2) AS total_sales,
COUNT(DISTINCT O.order_id) AS total_orders
FROM olist_customers_dataset C
JOIN olist_orders_dataset O ON C.customer_id = O.customer_id
JOIN olist_order_items_dataset OI ON O.order_id = OI.order_id
GROUP BY C.customer_unique_id
ORDER BY total_sales DESC;


--What is the average duration in days for each customer city?

SELECT C.customer_city, C.customer_state, 
AVG(DATEDIFF(DAY, O.order_purchase_timestamp, O.order_delivered_customer_date)) AS avg_shipping_duration,
COUNT(DISTINCT O.order_id) AS total_orders
FROM olist_customers_dataset C
JOIN olist_orders_dataset O ON O.customer_id = C.customer_id
WHERE O.order_delivered_customer_date IS NOT NULL AND
O.order_status = 'DELIVERED'
GROUP BY C.customer_city, C.customer_state
ORDER BY total_orders DESC;


--What is the percentage of delivered orders that were delivered late?

SELECT COUNT(DISTINCT O.order_id) AS total_delivered_orders,
SUM(CASE WHEN O.order_delivered_customer_date > O.order_estimated_delivery_date THEN 1 ELSE 0 END)
AS late_orders,
ROUND (SUM(CASE WHEN O.order_delivered_customer_date > O.order_estimated_delivery_date THEN 1 ELSE 0 END)
*100.0 /COUNT(DISTINCT O.order_id), 2) AS late_orders_percentage
FROM olist_orders_dataset O
WHERE O.order_status = 'delivered' and
o.order_delivered_customer_date IS NOT NULL;


--Which cities and states have the highest late delivery rate?

SELECT C.customer_city, C.customer_state, COUNT(DISTINCT O.order_id) AS total_orders,
SUM(CASE WHEN O.order_delivered_customer_date > O.order_estimated_delivery_date THEN 1 ELSE 0 END) 
AS late_orders,
ROUND (SUM(CASE WHEN O.order_delivered_customer_date > O.order_estimated_delivery_date THEN 0.1 ELSE 0.0 END)
*100.0 /COUNT(DISTINCT O.order_id), 2) AS late_delivery_rate
FROM olist_customers_dataset C
JOIN olist_orders_dataset O ON C.customer_id = O.customer_id
WHERE O.order_status = 'delivered' AND
O.order_delivered_customer_date IS NOT NULL
GROUP BY C.customer_city, C.customer_state
HAVING COUNT(DISTINCT O.order_id) >= 10
ORDER BY late_delivery_rate DESC;


--What is the overall average customer review score for olist?

SELECT ROUND(AVG(CAST(R.review_score AS FLOAT)),2) AS avg_review_score
FROM olist_order_reviews_dataset R;


--Does the delivery negatively impact customer review scores?

SELECT CASE 
WHEN O.order_delivered_customer_date > O.order_estimated_delivery_date THEN 'late delivery'
ELSE 'on time delivery' END AS delivery_status,
COUNT(DISTINCT O.order_id) AS total_orders,
ROUND(AVG(CAST(R.review_score AS FLOAT)),2) AS avg_review_score
FROM olist_orders_dataset O 
join olist_order_reviews_dataset R ON O.order_id = R.order_id
WHERE O.order_delivered_customer_date IS NOT NULL AND 
O.order_status = 'delivered'
GROUP BY CASE WHEN O.order_delivered_customer_date > O.order_estimated_delivery_date THEN 'late delivery'
ELSE 'on time delivery' END;


--What are the bottom 10 product categories with the lowest average review scores?

SELECT TOP 10 OC.product_category_name_english AS product_category,
COUNT(DISTINCT OI.order_id) AS total_orders,
ROUND(AVG(CAST(R.review_score AS FLOAT)),2) AS avg_review_score
FROM olist_order_items_dataset OI
JOIN olist_products_dataset P ON OI.product_id = P.product_id
JOIN olist_order_reviews_dataset R ON OI.order_id = R.order_id
JOIN olist_order_category_dataset OC ON P.product_category_name = OC.product_category_name
GROUP BY OC.product_category_name_english
ORDER BY avg_review_score ASC,total_orders DESC;


--Who are the bottom 10 sellers with the lowest average review scores?

SELECT TOP 10 S.seller_id,COUNT(DISTINCT OI.order_id) AS total_orders,
ROUND(AVG(CAST(R.review_score AS FLOAT)),2) AS avg_review_score
FROM olist_sellers_dataset S
JOIN olist_order_items_dataset OI ON OI.seller_id = S.seller_id
JOIN olist_order_reviews_dataset R ON R.order_id = OI.order_id
GROUP BY S.seller_id
HAVING COUNT(DISTINCT OI.order_id) >= 10
ORDER BY avg_review_score ASC, total_orders DESC;


--What are the most popular payment methods used by customers?

SELECT P.payment_type,COUNT(DISTINCT P.order_id) AS total_orders,
ROUND(SUM(P.payment_value), 2) AS total_payment_value
FROM olist_order_payments_dataset P
WHERE P.payment_type <> 'not_defined'
GROUP BY P.payment_type
ORDER BY total_orders DESC;


--Does the payment method vary based on the average order value?

SELECT P.payment_type,COUNT(DISTINCT P.order_id) AS total_orders,
ROUND(SUM(P.payment_value), 2) AS total_payment_value,
ROUND(AVG(P.payment_value), 2) AS avg_order_value
FROM olist_order_payments_dataset P
WHERE P.payment_type <> 'not_defined'
GROUP BY P.payment_type
ORDER BY avg_order_value













































