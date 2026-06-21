
--create table--
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


select * from Swiggy_data;


select count(*)
from Swiggy_data;

--Find the duplicate values--- 

select state, city,order_date, restaurant_name, Location, 
			category, dish_name, price_INR, Rating, Rating_count, count(*) as cnt
from swiggy_data
group by state, city, Order_date, restaurant_name,location, 
			category, Dish_name, price_INR, Rating, Rating_count
having count(*)>1;


--Remove duplicate values--

with CTE as( 
select *,
row_number() Over(Partition by
                   state, city, order_date, restaurant_name, location,
                   category, dish_name, price_inr, rating, rating_count
               ORDER BY (SELECT NULL)) as RN 
			   from swiggy_data
)
delete from swiggy_data
where exists(
	select 1
	from CTE
	where CTE.RN >1
);




