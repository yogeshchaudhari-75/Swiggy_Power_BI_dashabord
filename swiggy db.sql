create database Swiggy;


---create table--------------------------------
create table Swiggy_data(State Varchar (50),
City	Varchar(50),
Order_Date Date,
Restaurant_Name	Varchar (100),
Location	Varchar(50),
Category	Varchar(150),
Dish_Name	Varchar(150),
Price_INR	Numeric (10,2),
Rating numeric,
Rating_Count Numeric
);

select * from Swiggy_Data;


---copy and rename the table---------------------
-------------------------------------------------

select * into  swiggy from Swiggy_Data;
select * from swiggy;


----------------------BUSINESS REQUIREMENTS----------------------------------
-----------------------------------------------------------------------------
-------------------DATA CLEANING & VALIDATION--------------------------------

---STEP 1:NULL CHECK-----------------------------

select 
sum(case when State is null then 1 else 0 end),
sum(case when City is null then 1 else 0 end),
sum(case when Order_Date is null then 1 else 0 end),
sum(case when Restaurant_Name is null then 1 else 0 end),
sum(case when Location is null then 1 else 0 end),
sum(case when Category is null then 1 else 0 end),
sum(case when Dish_Name is null then 1 else 0 end),
sum(case when Price_INR is null then 1 else 0 end),
sum(case when Rating is null then 1 else 0 end),
sum(case when Rating_Count is null then 1 else 0 end)
FROM swiggy;

-----------------------------------------------------------------------------
---ANOTEHR METHOD TO NULL CHECK------------------

select *  from swiggy where State is null or
City is null or
Order_Date is null or
 Restaurant_Name is null or
 Location is null or
 Category is null or
 Dish_Name is null or
 Price_INR is null or
 Rating is null or
 Rating_Count is null 

---Blank or Empty strings------------------------

select * from swiggy
where state=''or city=''or Restaurant_Name=''or category=''
or Dish_Name='';

---Duplicate records find------------------------

select state,city,order_date,restaurant_name,location,
category,dish_name,price_inr,rating,rating_count,count(*) as CNT from swiggy
group by state,city,order_date,restaurant_name,location,
category,dish_name,price_inr,rating,rating_count
having count(*)>1;


---duplicate Deletion----------------------------

WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY 
                   state, city, order_date, restaurant_name, location,
                   category, dish_name, price_inr, rating, rating_count
               ORDER BY (SELECT NULL)
           ) AS rn
    FROM swiggy	
)

DELETE FROM swiggy
WHERE EXISTS (
    SELECT 1
    FROM cte
    WHERE cte.rn > 1);

select * from swiggy;


-------------------------SCHEMA REPRESENTATION-------------------------------
---DIM DATE--------------------------

create table Dim_Date(
Date_Id serial PRIMARY KEY,
Full_date DATE,
Year INT,
Month INT,
Month_name varchar(20),
Quarter INT, 
Day INT,
week int
);


select * from Dim_Date;

---DIM_LOCATION----------------------

create table Dim_Location(
Location_Id serial PRIMARY KEY,
State varchar(100),
City varchar(100),
Location varchar(200)
);

select * from Dim_Location;

---DIM_RESTAURANT--------------------

create table Dim_Restaurant(
Restaurant_Id serial PRIMARY KEY,
Restaurant_Name varchar(200)
);

select * from Dim_Restaurant;

---DIM_CATEGORY----------------------

create table Dim_Category(
Category_Id serial PRIMARY KEY,
Category varchar(200)
);

select * from Dim_Category;

---DIM_DISH--------------------------

create table Dim_Dish(
Dish_Id serial PRIMARY KEY,
Dish_name varchar(200)
);


select * from Dim_Dish;
select * from Dim_Category;
select * from Dim_Location;
select * from Dim_Date;
select * from Dim_Restaurant;

-----------------------------------------------------------------------------

---fact table -----------------------

create table fact_swiggy_orders(
    order_id serial primary key,
    date_id int,
    location_id int,
    restaurant_id int,
    category_id int,
    dish_id int,
    price_inr decimal(10,2),
    rating_count int,
    rating decimal(10,2),

    foreign key(location_id) references dim_location(location_id),
    foreign key(restaurant_id) references dim_restaurant(restaurant_id),
    foreign key(category_id) references dim_category(category_id),
    foreign key(dish_id) references dim_dish(dish_id),
    foreign key(date_id) references dim_date(date_id));


select * from fact_swiggy_orders;

-----------------------------------------------------------------------------
----------------NOW INSERT VALUES INTO DIM TABLES----------------------------

insert into dim_dish(dish_name)
select distinct dish_name from swiggy

select * from dim_dish;
select * from swiggy;

-----------------------------------------------------------------------------
insert into Dim_Restaurant(Restaurant_Name)
select distinct restaurant_name from swiggy;

select * from dim_restaurant;

-----------------------------------------------------------------------------

insert into Dim_category(category)
select distinct category from swiggy;

select * from Dim_category;

-----------------------------------------------------------------------------

insert into Dim_Location(state,city,location)
select distinct 
state,city,location from swiggy;

select * from Dim_location;

-----------------------------------------------------------------------------

INSERT INTO dim_date (
    full_date,
    year,
    month,
    month_name,
    quarter,
    day,
    week
)
SELECT DISTINCT
    order_date,
    EXTRACT(YEAR FROM order_date)::INT,
    EXTRACT(MONTH FROM order_date)::INT,
    TO_CHAR(order_date, 'Month'),
    EXTRACT(QUARTER FROM order_date)::INT,
    EXTRACT(DAY FROM order_date)::INT,
    EXTRACT(WEEK FROM order_date)::INT
FROM swiggy
WHERE order_date IS NOT NULL;

select * from dim_date;

-----------------------------------------------------------------------------

insert into fact_swiggy_orders(
    date_id,price_inr,rating,rating_count,location_id,restaurant_id,
category_id,dish_id)
select
    dd.date_id,
    s.price_inr,
    s.rating,
    s.rating_count,
    
    dl.location_id,
    dr.restaurant_id,
    dc.category_id,
    ds.dish_id
    
    from swiggy s

    join dim_date dd on dd.full_date=s.order_date

    join dim_location dl on dl.state=s.state and dl.city = s.city and dl.location=s.location

    join Dim_Restaurant dr on dr.Restaurant_Name=s.Restaurant_Name

    join Dim_Category dc on dc.Category=s.Category
    
	join Dim_dish ds on ds.dish_name=s.dish_name;

select * from fact_swiggy_orders;

-----------------------------------------------------------------------------

select * from fact_swiggy_orders as f
join dim_date d on f.date_id=d.date_id
join dim_location l on f.location_id=l.location_id
join Dim_Restaurant r on f.Restaurant_id=r.Restaurant_id
join Dim_category c on f.category_id=c.category_id
join Dim_dish di on f.dish_id=di.dish_id;

select * from fact_swiggy_orders;

---Total Orders-------------------------------------------

select count(*) as total_orders from fact_swiggy_orders;

---Total Revenue------------------------------------------

SELECT
    ROUND(SUM(price_inr) / 1000000, 2) || ' INR Million' AS total_revenue
FROM fact_swiggy_orders;

---Avg Dish Price-----------------------------------------

select round(avg(price_inr),2) as Avg_dish_price from fact_swiggy_orders;

---Avg Rating---------------------------------------------
 
select round(avg(rating),2) as avg_rating from fact_swiggy_orders;


-------------Date-Based Analysis----Monthly order trends---------------------

select
d.year,
d.month,
d.month_name, sum(price_inr) as Monthly_treds from fact_swiggy_orders f
join dim_date d on f.date_id=d.date_id
group by 
d.year,
d.month,
d.month_name
order by sum(price_inr) desc;

---Quarterly order trends---------------------------------

select
d.year,
d.quarter,
count(*) as Quarterly_Trends from fact_swiggy_orders f
join dim_date d on f.date_id=d.date_id
group by 
d.year,

d.quarter
order by count(*) desc;

---Year-wise growth---------------------------------------

select d.year,
count(*) as Year_trends
from fact_swiggy_orders f
join dim_date d on f.date_id = d.date_id
group by d.year
order by count(*) desc;


-------------------Location-Based Analysis-----------------------------------
---Top 10 cities by order volume--------------------------

select l.city,sum(price_inr) as order_volume from fact_swiggy_orders f
join dim_location l on f.Location_Id=l.location_id
group by city 
order by sum(price_inr) desc limit 10;


---Revenue contribution by states--------------------------------------------


select l.State,sum(price_inr) as revenue_contribution from fact_swiggy_orders f
join dim_location l on l.Location_Id=f.location_id
group by state
order by sum(price_inr) desc;

---------Food Performance----------------------------------------------------
---Top 10 restaurants by orders---------------------------

select r.Restaurant_Name,sum(f.price_inr) as Order_value from fact_swiggy_orders f
join Dim_Restaurant r on r.Restaurant_Id=f.restaurant_id
group by Restaurant_Name
order by sum(price_inr) desc limit 10;


---Top categories (Indian, Chinese, etc.)------------------

select * from dim_category;

select c.category,count(*) from fact_swiggy_orders f
join dim_category c on c.category_id=f.category_id
group by category
order by count(*) desc;


---Most ordered dishes-------------------------------------

select * from dim_dish;

select di.dish_name,count(*) from fact_swiggy_orders f
join dim_dish di on di.dish_id=f.dish_id
group by dish_name
order by count(*) desc;

---Cuisine performance → Orders + Avg Rating---------------

select c.category,count(*) as orders,
round(avg(rating),2) as avg_rating
from fact_swiggy_orders f
join dim_category c on c.category_id=f.category_id
group by category
order by count(*) desc;


--------------------Customer Spending Insights-------------------------------
--------------------Buckets of customer spend:-------------------------------
---Under 100,,100–199,,200–299,,,300–499,,500+-------------

SELECT
    price_range,
    COUNT(*) AS order_count
FROM (
    SELECT
        CASE
            WHEN price_inr < 100 THEN 'Under 100'
            WHEN price_inr BETWEEN 100 AND 199 THEN '100-199'
            WHEN price_inr BETWEEN 200 AND 299 THEN '200-299'
            WHEN price_inr BETWEEN 300 AND 399 THEN '300-399'
            ELSE '500+'
        END AS price_range
    FROM fact_swiggy_orders
) t
GROUP BY price_range
ORDER BY order_count DESC;

---------------------------Ratings Analysis----------------------------------
---Distribution of dish ratings from 1–5-------------------

select * from fact_swiggy_orders;

select rating,count(*) as rating_count from fact_swiggy_orders
group by rating
order by count(*) desc;

-----------------------------------------------------------------------------
-----------------------------------END---------------------------------------
















