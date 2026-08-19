USE ecommerce_db;
SELECT * FROM customers
    
SELECT * FROM products 
SELECT * FROM orders
SELECT * FROM order_items 

--1. Calculate Total Revenue
SELECT (quantity * unit_price ) AS total_rev
From order_items;

--2 Count Total Orders
SELECT COUNT(order_id) as Total_orders
From orders;

-- 3 Count Total Customers
SELECT count(customer_id) AS total_customer
From customers;

-- 4. Count Total Products
SELECT count(product_id) AS total_customer
From products;

--5. Calculate Average Order Value (AOV)
SELECT Avg(total_order) As AOV
From (
Select SUM(unit_price * quantity) AS total_order
FROM order_items
GROUP By order_id
);

--6 Find Top 5 Selling Products
SELECT P.product_name , SUM(O.quantity) As total_quantity
From products P
JOIN order_items O
On P.product_id = O.product_id
GROUP BY P.product_name
ORDER BY total_quantity DESC
LIMIT 5;

-- 7 Find Revenue by Product Category
SELECT P.category, SUM (O.unit_price * O.quantity) As total_revenue
FROM products P
JOIN order_items O
on P.product_id = O.product_id
Group By P.category
Order By total_revenue DESC;

--Find Top 5 Customers by Revenue
SELECT C.customer_name, SUM (O.unit_price * O.quantity) As total_revenue
FROM customers C
JOIN orders O1
on C.customer_id = O1.customer_id
JOIN order_items O
on O1.order_id = O.order_id
Group By C.customer_name
Order By total_revenue DESC
limit 5;

-- 9 Calculate Monthly Revenue
SELECT 
To_CHAR(O.order_date, 'FMMonth') AS month_name, 
SUM(O1.quantity * O1.unit_price) As revenue_per_month
From orders O
JOIN order_items O1
On O.order_id = O1.order_id
Group By month_name;

-- 10 Find Revenue by City
SELECT C.city As City,
		SUM(O1.quantity * O1.unit_price) As revenue_by_city
From customers C
JOIN orders O
on C.customer_id = O.customer_id
JOIN order_items O1
on O.order_id = O1.order_id
Group By C.city
Order By revenue_by_city DESC;


--11 Find Repeat Customers

Select C.customer_id,C.customer_name, COUNT (O.customer_id)
From customers C
JOIN orders O
on  C.customer_id = O.customer_id
Group By C.customer_id,customer_name
Having Count(O.customer_id) >1;



--12. Find Customers Who Never Placed an Order
Select C.customer_id,C.customer_name, COUNT (O.customer_id)
From customers C
Left JOIN orders O
on  C.customer_id = O.customer_id
Group By C.customer_id,customer_name
Having Count(O.customer_id) =0;


--13. Find Inactive Customers (No Orders in the Last 90 Days)
Select C.customer_id,C.customer_name, Max(O.order_date)
From customers C
Left JOIN orders O
on  C.customer_id = O.customer_id
Group By C.customer_id,customer_name
Having Max(O.order_date) < Current_DATE - INTERVAL '90 days';



--14. Find the Best-Selling Product Category
Select  
	P.category, 
	SUM(O.quantity) As total_quantity
From Products P 
JOIN order_items O
ON 
	P.product_id = O.product_id
group By 
	P.category
Order By total_quantity DESC;



--15. Find the Highest Revenue Product
Select P.product_name, Sum(O.quantity * O.unit_price) As revenue
From Products P
JOIN Order_items O
On P.product_id= O.product_id
Group By P.product_name
Order By revenue DESC
Limit 1;


--16. Find the Lowest Revenue Product
Select P.product_name, Sum(O.quantity * O.unit_price) As Lowest_revenue
From Products P
JOIN order_items O
ON P.product_id = O.product_id
Group By P.product_name
Order By lowest_revenue
Limit 1;



--17. Calculate Average Products per Order
Select order_id, Avg(Product_quantity) As Avg_Product_quantity
From (
Select O.order_id As Order_id, Sum (o.quantity) As Product_quantity
From order_items O
Group By O.order_id
)
Group By order_id;


18. Find Orders Worth More Than 10,000
Select order_id, SUM(unit_price * quantity) As Price
From order_items
GRoup By order_id
Having SUM(unit_price * quantity)> 10000;




--19. Find Customers with the Highest Average Order Value

Select full_name, Avg(Order_value) As Avg_Order_value
From
(Select C.customer_name As  full_name, SUM(O.unit_price * O.quantity) As Order_value
From customers C
JOIN orders O1
ON C.customer_id = O1.customer_id
JOIN order_items O
On O1.order_id = O.order_id
Group By C.customer_name, C.customer_id, O1.order_id
)
Group By full_name
Order By Avg_order_value DESC
LIMIT 1;

--20. Find the Top 3 Cities by Revenue
Select C.city, SUM(O.unit_price * O.quantity) As revenue
From customers C
JOIN orders O1
ON C.customer_id = O1.customer_id
JOIN order_items O
On O1.order_id = O.order_id
Group By C.city
Order By revenue DESC
limit 3;



--21 Rank Customers by Total Revenue*
With customer_revenue As (
Select C.customer_name As customer_name, SUM(O.quantity * O.unit_price) As revenue
From customers C
Join orders O1
on C.customer_id = O1.customer_id
JOIN order_items O
on O1.order_id = O.order_id
Group By C.customer_name)
Select customer_name, revenue,
Rank() Over(Order By revenue DESC) As revenue_rank
From customer_revenue;



--22. Find the Top Selling Product in Each Category
With quantity As (
	Select P.product_name As product_name, P.category As category,  Sum(O.quantity) As total_quantity
	From products P
	JOIN order_items O
	ON P.product_id  = O.product_id
	Group By P.product_name,P.category
	) ,
ranked As (Select product_name, category, total_quantity,
		Rank() Over( 
				Partition By category
				Order By total_quantity DESC
				) As rank_order
		From quantity
		)
Select product_name,category, total_quantity, rank_order
From ranked
Where rank_order =1 ;


--23. Calculate Running Revenue by Order Date*
With date_revenue As 
	(Select O1.order_date As order_date, Sum(O.quantity * O.unit_price) as revenue
	From orders O1
	JOIN order_items O
	ON O1.order_id = O.order_id
	Group By order_date)
Select order_date, 	
	Sum(revenue) Over( Order By order_date)
	From date_revenue;


--24 Find the Previous Order Date for Each Customer
Select customer_id, order_id, order_date,
	LAg(order_date) Over (
		PArtition By customer_id
		Order By order_date
		
	) As previious_order_date

From orders;

--25. Find the Next Order Date for Each Customer
Select customer_id, order_id, order_date,
	LEAD (order_date) Over (
		PArtition By customer_id
		Order By order_date
		
	) As next_order_date

From orders;


--26. Calculate Days Between Consecutive Orders*
Select customer_id, order_id, order_date,
		order_date- LAG (order_date) Over(
			Partition By customer_id
			Order By order_date
		) As days_between_orders
From orders;


--27. Find the Top 3 Customers by Revenue*
WITH revenue As
(Select C.customer_id, C.customer_name, Sum(O.quantity * O.unit_price) As revenue
From customers C
JOIn orders O1
on C.customer_id = O1.customer_id
JOIN order_items O
on O1.order_id = O.order_id
group by C.customer_name,C.customer_id
) ,
ranked AS (
	Select customer_id, customer_name , revenue,
		Rank () Over (
 		Order by revenue DESC
		) As ranked_customer
	From revenue
)
Select * from ranked
Where ranked_customer =3;


--28. Find Each Product's Contribution to Total Revenue
With revenue_per_product AS (
Select product_id , Sum(quantity * unit_price) As revenue
From order_items
GROUP BY product_id
)

Select product_id,Round (revenue /Sum (revenue ) Over() * 100,2) As total_revenue
	From revenue_per_product
	;
	



--29. Find Monthly Revenue Growth*'
With 
Monthly_Revenue As (Select DATE_trunc ('month', O1.order_date ) As months,
		Sum(O.quantity * O.unit_price) As revenue
From orders O1
JOIN order_items O
On O1.order_id = O.order_id
Group By DATE_trunc ('month', O1.order_date )),

Previous_month AS 
(Select months, revenue,LAG(revenue) Over( Order By months) AS pre_month
From Monthly_Revenue)

Select 
	(revenue - pre_month)/pre_month *100 AS monthly_growth
FROM Previous_month;


--30. Find the Highest Value Order for Each Customer*
With order_price As (
	Select O.order_id, C.customer_name, SUM(O.unit_price * O.quantity) as Order_value
	From customers C
	JOIN orders O1
	on C.customer_id = O1.customer_id
	JOIN order_items O
	On O1.order_id = O.order_id
	Group By customer_name,O.order_id)
Select customer_name, Max(order_value) As highest_order_value
From order_price 
Group by customer_name;


--31. Calculate Customer Lifetime Value (CLV)
SELECT C.customer_name,
       SUM(O.unit_price * O.quantity) AS CLV
FROM customers C
JOIN orders O1
    ON C.customer_id = O1.customer_id
JOIN order_items O
    ON O1.order_id = O.order_id
GROUP BY customer_name;



--32. Calculate Repeat Purchase Rate*
With repeat_customers As(
	Select C.customer_id, C.customer_name, Count (O.customer_id) AS repeated
	From customers C 
	Join orders O
	on C.customer_id = O.customer_id
	Group by C.customer_id, C.customer_name
	Having Count(O.customer_id)> 1)

Select (
Round ((Select Count (*) From repeat_customers)::numeric / (Select Count(*) From customers) * 100,2)
);

