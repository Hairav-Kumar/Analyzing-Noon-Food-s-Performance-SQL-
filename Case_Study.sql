use company;
-- Create the orders table
CREATE TABLE orders (
    Order_id VARCHAR(20),
    Customer_code VARCHAR(20),
    Placed_at DATETIME,
    Restaurant_id VARCHAR(10),
    Cuisine VARCHAR(20),
    Order_status VARCHAR(20),
    Promo_code_Name VARCHAR(20)
);

-- Noon launched Food in Dubai on 1st of Jan and your line manager has asked you to share key performance metrics to gauge the performance of the verticals. 
-- All the data of orders is being stored in the below table kindly use this table to write queries to find the insights

Select * from orders;

-- Q1 - Find top 1 outlets by cuisine type without using limit and top function?
with cte as (select Restaurant_id,Cuisine,count(*) as no_of_order from orders group by Restaurant_id,Cuisine)
select Restaurant_id ,Cuisine from (select * ,dense_rank() over(partition by cuisine order by no_of_order desc) as rnk from cte) x where rnk = 1;

-- Q2 - Find the daily new customer count from the launch date (everyday how many new customers are we acquiring)
with cte as (select Cast(Placed_at as Date) as _Date,Customer_code,row_number() over(partition by Customer_code order by Cast(Placed_at as Date)) as rnk  from orders)
select _Date,count(Customer_code) as new_customer from cte where rnk =1 group by _Date order by _Date;

-- 2nd Method
with cte as (select Customer_code,min(cast(Placed_at as date)) as first_order_date from orders group by Customer_code)
select first_order_date,count(Customer_code) as new_customer from cte group by first_order_date;

-- Q3 - Count of all the users who were acquired in jan 2025 and only placed one order in Jan did not place any other order in 2025

with cte as (select Customer_code from orders where year(Placed_at) = 2025 and month(Placed_at)=1 group by Customer_code having count(distinct Order_id)=1)
select count(*) as customer_count from cte where Customer_code not in (select distinct Customer_code from orders where year(Placed_at) = 2025 and month(Placed_at)!=1);


-- Q4 - List all the customers with no order in the last 7 days but were acquired one month ago with their first order on promo?
with cte as (select Customer_code,min(Placed_at) as first_order, max(Placed_at) as latest_order from orders group by Customer_code)
select c.Customer_code from cte as c join orders as o on c.Customer_code=o.Customer_code and c.first_order=o.Placed_at where latest_order <
date_sub(cast(sysdate() as date),interval 7 day) and first_order < date_sub(cast(sysdate() as date),interval 1 month) and Promo_code_Name is not null;

-- Q5 - Growth team is planning to create a trigger that will target customers after their every third order with a personalized commnuication and they have asked to create a query for this?
with cte as (select Customer_code,dense_rank() over(partition by Customer_code order by Placed_at) as order_rnk from orders)
select distinct Customer_code from cte where order_rnk%3=0;

-- Q6 - List customers who placed more than 1 order and all their orders on a promo only?
with cte as (select Customer_code,count(*) as no_of_orders, count(Promo_code_Name) as promo_orders from orders group by Customer_code)
select Customer_code from cte where no_of_orders>1 and no_of_orders=promo_orders;

-- Q7 - What percent of customers were organically acquired in Jan 2025. Placed their first order without promo code?

with cte as (select count(Customer_code) as org_cust from (select Customer_code,Promo_code_Name,row_number() over(partition by Customer_code order by Placed_at) 
as rnk from orders where month(Placed_at)=1 and year(Placed_at)=2025)x where rnk =1 and Promo_code_Name is null)

select (org_cust/(select count( distinct Customer_code) from orders where month(Placed_at)=1 and year(Placed_at)=2025))*100 as percentage from cte;

-- 2nd Method
with cte as (select Customer_code,Promo_code_Name,row_number() over(partition by Customer_code order by Placed_at) 
as rnk from orders where month(Placed_at)=1 and year(Placed_at)=2025)
select count(case when rnk=1 and Promo_code_Name is null then Customer_code end)*100/count(distinct Customer_code) as percentage from cte;



