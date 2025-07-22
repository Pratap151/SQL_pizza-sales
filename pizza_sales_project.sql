CREATE DATABASE pizzahut;

CREATE TABLE orders (
order_id INT NOT NULL,
order_date DATE NOT NULL,
order_time TIME NOT NULL,
PRIMARY KEY(order_id)
);



CREATE TABLE order_details (
order_details_id INT NOT NULL,
order_id INT NOT NULL,
pizza_id TEXT NOT NULL,
quantity INT NOT NULL,
PRIMARY KEY(order_details_id)
);

SELECT * FROM order_details;



-- 1. Retrieve the total number of orders placed.
SELECT COUNT(order_id) AS total_order_placed FROM orders;



-- 2. Calculate the total revenue generated from pizza sales.
SELECT * FROM pizzas; -- pizza_id, pizza_type_id
SELECT * FROM order_details; -- order_details_id, order_id, pizza_id

SELECT ROUND(SUM(p.price * od.quantity), 2) AS total_revenue
FROM pizzas p
JOIN order_details od
ON p.pizza_id = od.pizza_id;



-- 3. Identify the highest-priced pizza.

SELECT pt.name, p.price
FROM pizza_types pt
JOIN pizzas p
ON pt.pizza_type_id = p.pizza_type_id
ORDER BY p.price DESC
LIMIT 1;


-- 4. Identify the most common pizza size ordered.


SELECT p.size, COUNT(od.quantity) total_qty
FROM pizzas p
JOIN order_details od
ON p.pizza_id = od.pizza_id
GROUP BY p.size
ORDER BY total_qty DESC;



-- 5. List the top 5 most ordered pizza types along with their quantities.

SELECT pt.name, SUM(od.quantity) AS total_qty
FROM pizzas p
JOIN pizza_types pt
ON p.pizza_type_id = pt.pizza_type_id
JOIN order_details od
ON od.pizza_id = p.pizza_id
GROUP BY 1 
ORDER BY total_qty DESC
LIMIT 5;




-- 6. Join the necessary tables to find the total quantity of each pizza category ordered.


SELECT pt.category, SUM(od.quantity) total_qty
FROM pizzas p
JOIN order_details od 
ON p.pizza_id = od.pizza_id
JOIN pizza_types pt 
ON pt.pizza_type_id = p.pizza_type_id
GROUP BY 1
ORDER BY total_qty DESC;


-- 7. Determine the distribution of orders by hour of the day.

select HOUR(order_time) AS per_hour, count(order_id) AS order_qty
from orders
group by 1;


-- 8. Join relevant tables to find the category-wise distribution of pizzas.
SELECT category, COUNT(name) 
FROM pizza_types
GROUP BY category;


-- 9. Group the orders by date and calculate the average number of pizzas ordered per day.

-- SELECT * FROM orders;
-- SELECT * FROM order_details;

SELECT ROUND(AVG(avg_qty)) AS avg_qty_per_day
FROM	
		(SELECT o.order_date, SUM(od.quantity) AS avg_qty
		FROM orders o
		JOIN order_details od
		ON o.order_id = od.order_id
		GROUP BY 1
		ORDER BY o.order_date) A;
        
-- 10. Determine the top 3 most ordered pizza types based on revenue.

-- select * from pizza_types;
      
SELECT pt.name, SUM(p.price * od.quantity) AS total_revenue
FROM pizzas p
JOIN pizza_types pt
ON pt.pizza_type_id = p.pizza_type_id
JOIN order_details od
ON p.pizza_id = od.pizza_id
GROUP BY 1
ORDER BY total_revenue DESC
LIMIT 3;




-- 11. Calculate the percentage contribution of each pizza type to total revenue.

--  WAY 01

WITH category_wise_revenue AS
	(SELECT pt.category, ROUND(SUM(p.price * od.quantity), 2) AS category_revenue
	FROM pizza_types pt
	JOIN pizzas p
	ON pt.pizza_type_id = p.pizza_type_id
	JOIN order_details od
	ON od.pizza_id = p.pizza_id
	GROUP BY 1)
    
SELECT category, category_revenue, CONCAT(ROUND((category_revenue / 
								(SELECT  ROUND(SUM(od.quantity * p.price)) AS total_revenue
								FROM  order_details od
								JOIN pizzas p
								ON od.pizza_id = p.pizza_id)) * 100, 2), ' %') AS per_contribution
                                
FROM category_wise_revenue
ORDER BY per_contribution DESC;                                

-- WAY 02    
SELECT pt.category, ROUND(SUM(p.price * od.quantity), 2) AS category_revenue,
CONCAT(ROUND(ROUND(SUM(p.price * od.quantity), 2) / (SELECT ROUND(SUM(od.quantity * p.price))
FROM  order_details od
JOIN pizzas p
ON od.pizza_id = p.pizza_id) *100, 2), ' %')  AS contribution
FROM pizza_types pt
JOIN pizzas p
ON pt.pizza_type_id = p.pizza_type_id
JOIN order_details od
ON od.pizza_id = p.pizza_id
GROUP BY 1
ORDER BY contribution DESC;



-- 12. Analyze the cumulative revenue generated over time.
    
WITH per_day_revenue AS

(SELECT o.order_date, ROUND(SUM(p.price * od.quantity), 2) AS revenue
FROM pizzas p
JOIN order_details od
ON p.pizza_id = od.pizza_id
JOIN orders o
ON o.order_id = od.order_id
GROUP BY 1)

SELECT order_date, revenue, 
SUM(revenue) OVER(ORDER BY order_date) AS cumulative_revenue
FROM per_day_revenue;


-- 13. Determine the top 3 most ordered pizza types based on revenue for each pizza category.

WITH revenue_rank AS

(SELECT category, name, revenue,
RANK() OVER (PARTITION BY category ORDER BY revenue DESC ) AS ranking
FROM 
(select pt.category, pt.name, ROUND(SUM(p.price * od.quantity), 2) AS revenue
FROM pizzas p
JOIN order_details od
ON p.pizza_id = od.pizza_id
JOIN pizza_types pt
ON pt.pizza_type_id = p.pizza_type_id
GROUP BY pt.category, pt.name) A)

SELECT * FROM revenue_rank
WHERE ranking <= 3;






