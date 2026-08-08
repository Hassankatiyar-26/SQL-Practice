--1
SELECT * FROM categories;
--2
SELECT * FROM stores;
--3
SELECT * FROM employees;
--4
SELECT * FROM products;
--5
SELECT DISTINCT first_name FROM customers;
--6
SELECT * FROM orders;
--7
SELECT * FROM order_items;


/* Level 1 — SELECT / WHERE / JOINS (warm up) */
--1.	List all products with their category name, sorted by unit price descending.
SELECT  P.product_name, C.category_name, P.unit_price
From products P
JOIN categories C
ON P.category_id = C.category_id
	ORDER BY P.unit_price DESC;

--2.	Find all completed orders placed in 2024, showing customer name, store name, and order date.
SELECT O.order_id, C.first_name, C.last_name, S.store_name, O.order_date
FROM orders O
JOIN customers C
ON O.customer_id = C.customer_id
JOIN stores S
ON O.store_id = S.store_id
WHERE  order_date BETWEEN '2024-01-01' AND '2024-12-31';


--3.	Which employees work at stores in Pakistan? Show their name, role, store, and city.
SELECT E.first_name, E.last_name, E.role, S.store_name, S.city
FROM employees E
JOIN stores S
ON E.store_id = S.store_id
WHERE S.country = 'Pakistan';



--Level 2 — Aggregates + GROUP BY/HAVING

--4. Total revenue per category — revenue = quantity × unit_price × (1 - discount).

SELECT C.category_name, SUM(O.quantity * O.unit_price * (1 - O.discount)) AS revenue
FROM order_items O
JOIN products P
ON O.product_id = P.product_id
JOIN categories C
ON P.category_id =  C.category_id
GROUP BY C.category_name;


--5. Top 5 customers by total amount spent.
SELECT  C.first_name, C.last_name,SUM(O.quantity * O.unit_price) As total_amount_spent
FROM order_items O
JOIN orders O2
ON O.order_id =O2.order_id
JOIN customers C
ON o2.customer_id = C.customer_id
Group By C.customer_id
ORDER by total_amount_spent DESC
LIMIT 5;



--6. Stores where average order value exceeds $500 (HAVING).
SELECT S.store_name, AVG(OT.unit_price* OT.quantity)
FROM stores S
JOIN orders O
ON S.store_id = O.store_id
JOIN order_items OT
ON O.order_id = OT.order_id
GROUP BY S.store_name
Having AVG(OT.unit_price* OT.quantity) >500;


--7. Count of orders per payment method, only show methods with more than 300 orders.
SELECT  O.payment_method,COUNT(O.order_id)
FROM orders O
GROUP BY O.payment_method
Having COUNT(O.order_id) > 300 ;


--Level 3 — CASE Statements
/*8. Label each customer by loyalty tier value — Platinum = 'VIP', 
Gold = 'Priority', Silver = 'Standard', Bronze = 'Basic' using CASE */.

SELECT first_name, loyalty_tier ,
CASE
WHEN loyalty_tier= 'Platinum' THEN 'VIP'
WHEN loyalty_tier= 'Gold' THEN 'Priority'
WHEN loyalty_tier= 'Silver' THEN 'Standard'
WHEN loyalty_tier= 'Bronze' THEN 'Basic'
ELSE 'NOT Found'
END AS labels
FROM customers;


--9. Classify each product's profit margin as 'High' (>50%), 'Medium' (25–50%), 
--or 'Low' (<25%) using CASE — margin = (unit_price - cost_price) / unit_price.
WIth margin1 As
(
SELECT product_id,ROUND(((unit_price - cost_price)/unit_price)* 100,2) AS margin
FROM products
)
SELECT P.product_name, 
CASE 
WHEN M.margin >50 THEN 'High'
WHEN M.margin BETWEEN 25 AND 50 THEN 'Medium'
WHEN M.margin <25 THEN 'Low'
else 'Not Found'
END As product_classification
FRom products P 
Join margin1 M
ON P.product_id = M.product_id;





--10. Flag each order as 'At Risk' if status is 'returned' or 'cancelled', otherwise 'Healthy'.

SELECT order_id,status ,
CASE
WHEN status= 'returned' OR status ='cancelled' THen 'At Risk'
ELSE 'Healthy'
END As status_flag
from orders;

/*Level 4 — COALESCE / NULL Handling */

--11. Some products may have NULL stock — use COALESCE to show 0 instead of NULL for stock quantity.
SELECT  product_name, COALESCE (stock_quantity, 0) FROM products


	
--12. Build a customer summary showing full name, city, and loyalty tier
--— if loyalty tier is NULL show 'Unregistered'.
SELECT 	CONCAT (first_name, ' ', last_name) AS full_name, city, 
COALESCE (loyalty_tier, 'Unregistered') As loyalty_tier
FROM customers;

--Level 5 — Subqueries & CTEs
--13. Find products whose unit price is above the average unit price of their category (correlated subquery).
SELECT product_name, unit_price
FROM products P1
WHERE unit_price > (
SELECT Avg (unit_price)
FROM products P2
WHERE P1.category_id = P2.category_id
);

--14. Using a CTE, calculate total revenue per store, then find stores performing above the overallaverage revenue.
With 
total_revenue AS (
SELECT S.store_name AS store_name, SUM(O.quantity * O.unit_price) AS total_revenue_per_store
FROM stores S
JOIN orders O1
On S.store_id = O1.store_id
JOIN order_items O
On O1.order_id = O.order_id
Group By S.store_name
)
Select  T.store_name, T.total_revenue_per_store 
FROM  total_revenue T 
Where T.total_revenue_per_store >
(Select Avg (T.total_revenue_per_store)
FRom total_revenue T );

--15. Find the top-spending customer per country using a subquery.
SELECT C1.full_name,C1.total_money_spend,C1.country
From (
		Select
		C.customer_id,
		CONCAT(C.first_name,' ', C.last_name) AS Full_name,C.country AS country,
		SUM(O.quantity * O.unit_price) AS total_money_spend
	FROM customers C
	JOIN orders O1
		On C.customer_id = O1.customer_id
	JOIN order_items O
		On O1.order_id = O.order_id
Group By C.first_name,C.last_name,C.country,C.customer_id
) AS C1
Where C1.total_money_spend = (
	Select  Max(C2.total_money_spend)
	From (
	Select 
	C.customer_id,
	C.country AS country,
	SUM(O.quantity * O.unit_price) AS total_money_spend
FROM customers C
JOIN orders O1
On C.customer_id = O1.customer_id
JOIN order_items O
On O1.order_id = O.order_id
Group By C.customer_id,C.country
) AS C2
Where C2.country = C1.country
);

--Level 6 — Window Functions
--16. Rank employees by salary within each store using RANK() OVER (PARTITION BY store_id ORDER BY salary DESC).
SELECT Concat (E.first_name, ' ', E.last_name) AS Full_name, E.salary,
		RANK() Over(Partition By store_id Order By salary DESC)
		FROM employees E;


--17. For each order, show the running total revenue per store ordered by date using SUM() OVER.
SELECT
    order_id,
    store_id,
    order_date,
    order_revenue,
    SUM(order_revenue) OVER (
        PARTITION BY store_id
        ORDER BY order_date
    ) AS running_total_revenue
FROM (
    SELECT
        O.order_id,
        O1.store_id,
        O1.order_date,
        SUM(O.quantity * O.unit_price) AS order_revenue
    FROM order_items O
    JOIN orders O1
        ON O.order_id = O1.order_id
    GROUP BY O.order_id, O1.store_id, O1.order_date
) AS order_totals;

--18. Use ROW_NUMBER() to find the first order placed by each customer (their very first purchase date).
 SELECT *
 FROM(
 SELECT Concat (C.first_name,' ', C.last_name) AS full_name, O.order_id,C.customer_id, 
		ROW_NUMBER() Over (
		PARTITION BY C.customer_id
		Order By O.order_date
		) As order_num
		FROM customers C
		JOIN orders O
		On C.customer_id = O.customer_id
		) AS ranked
		WHERE order_num =1;




