-- SQL II - Mini Project
use proj2;
/* Composite data of a business organisation, confined to ‘sales and delivery’
domain is given for the period of last decade. From the given data retrieve
solutions for the given scenario. */

/* 1. Join all the tables and create a new table called combined_table.
(market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen) */
CREATE TABLE Combined_Table AS
(SELECT *
FROM cust_dimen
NATURAL JOIN market_fact
NATURAL JOIN orders_dimen
NATURAL JOIN prod_dimen
NATURAL JOIN shipping_dimen);
select * from combined_table;

-- 2. Find the top 3 customers who have the maximum number of orders
SELECT CUST_ID,CUSTOMER_NAME,count(ord_id) AS total_orders
from combined_table
group by customer_name
ORDER BY COUNT(ORD_ID) DESC
LIMIT 3;

/* 3. Create a new column DaysTakenForDelivery that contains the date difference
of Order_Date and Ship_Date. */
alter table combined_table
add DaysTakenForDelivery int;
set sql_safe_updates=0;
update combined_table
set order_date= str_to_date(order_date,'%d-%c-%Y'),
ship_date=str_to_date(ship_date,'%d-%c-%Y');
update combined_table
set DaysTakenForDelivery=datediff(ship_date,order_date);
select *
from combined_table;

-- 4. Find the customer whose order took the maximum time to get delivered.
select cust_id,customer_name,DaysTakenForDelivery
from combined_table
where DaysTakenForDelivery = (select max(DaysTakenForDelivery) from combined_table);


/* 5. Retrieve total sales made by each product from the data (use Windows
function) */
with total_sales_table as (select prod_id,product_category,product_sub_category,
sum(sales) over (partition by product_sub_category) as total_Sales
from combined_table)
select prod_id,product_category,product_sub_category,round(total_sales,2) as Total_Sales
from total_sales_table;

/* 6. Retrieve total profit made from each product from the data (use windows
function) */
with total_profit_table as (select prod_id,product_category,product_sub_category,
sum(profit) over (partition by product_sub_category) as total_profit
from combined_table)
select prod_id,product_category,product_sub_category,round(total_profit,2) as total_profit
from total_profit_table
where total_profit > 0;

/* 7. Count the total number of unique customers in January and how many of them
came back every month over the entire year in 2011 */
SELECT Year(order_date),
Month(order_date),
count(distinct cust_id) AS number
FROM combined_table
WHERE year(order_date)=2011
AND cust_id IN (SELECT DISTINCT cust_id
      FROM            combined_table
      WHERE           month(order_date)=1
      AND             year(order_date)=2011 )
GROUP BY 1,2;

/* 8. Retrieve month-by-month customer retention rate since the start of the
business.(using views)
Tips:
#1: Create a view where each user’s visits are logged by month, allowing for
the possibility that these will have occurred over multiple # years since
whenever business started operations
# 2: Identify the time lapse between each visit. So, for each person and for each
month, we see when the next visit is.
# 3: Calculate the time gaps between visits
# 4: categorise the customer with time gap 1 as retained, >1 as irregular and
NULL as churned
# 5: calculate the retention month wise */
CREATE VIEW user_visits AS 
SELECT cust_id,customer_name,order_Date,YEAR(order_date),MONTH(order_date),COUNT(cust_id) OVER (PARTITION BY YEAR(order_date) ORDER BY MONTH(order_date)) as visits
FROM combined_table;
select * from user_visits;

create view time_difference as 
(select cust_id,year(order_Date),month(order_Date) AS order_month,
lead(month(order_Date),1) over (partition by cust_id order by cust_id) AS lead_month, 
lead(month(order_Date),1) over (partition by cust_id order by cust_id)  - month(order_Date) as time_lapse
from user_visits
where year(order_Date)='2009'
union all
select cust_id,year(order_Date),month(order_Date) AS order_month,
lead(month(order_Date),1) over (partition by cust_id order by cust_id) AS lead_month, 
lead(month(order_Date),1) over (partition by cust_id order by cust_id)  - month(order_Date) as time_lapse
from user_visits
where year(order_Date)='2010'
union all
select cust_id,year(order_Date),month(order_Date) AS order_month,
lead(month(order_Date),1) over (partition by cust_id order by cust_id) AS lead_month, 
lead(month(order_Date),1) over (partition by cust_id order by cust_id)  - month(order_Date) as time_lapse
from user_visits
where year(order_Date)='2011'
union all
select cust_id,year(order_Date),month(order_Date) AS order_month,
lead(month(order_Date),1) over (partition by cust_id order by cust_id) AS lead_month, 
lead(month(order_Date),1) over (partition by cust_id order by cust_id)  - month(order_Date) as time_lapse
from user_visits
where year(order_Date)='2012');
select * from time_difference;

create view cust_category as
select cust_id,order_month,
case when time_lapse=1 then 'retained'
	 when time_lapse>1 then 'irregular'
     else 'churned'
end as cust_type
from time_difference;
select * from cust_category;

select order_month,cust_type,count(cust_id) as total_retained_customers
from cust_category
where cust_type='retained'
group by 1,2
order by order_month;