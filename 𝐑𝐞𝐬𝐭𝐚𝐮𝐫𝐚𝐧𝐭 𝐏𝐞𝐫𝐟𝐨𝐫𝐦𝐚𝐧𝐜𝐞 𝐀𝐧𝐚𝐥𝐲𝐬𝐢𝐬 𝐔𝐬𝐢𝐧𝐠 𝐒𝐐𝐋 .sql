create database cbchallange1;

use cbchallange1;

-- Total Data Files

select *from dim_date
select *from dim_rooms
select *from dim_hotels
select *from fact_bookings
select *from fact_aggregated_bookings

-- Data Cleaning

alter table fact_bookings alter column revenue_realized bigint
alter table fact_bookings alter column ratings_given int
alter table fact_aggregated_bookings alter column capacity int
alter table fact_aggregated_bookings alter column successful_bookings int
alter table dim_date alter column dates date
alter table fact_bookings alter column booking_date date
alter table fact_bookings alter column check_in_date date

exec sp_rename 'dim_date.date' , dates , 'column'
exec sp_rename 'dim_date.week no' , weeks , 'column'

-- Data Analysis

-- Total Revenue
select 
sum("revenue_realized") as "Total Revenue"
from fact_bookings

-- Total Bookings
select 
count(booking_id) as 'Total Bookings'
from fact_bookings

-- Total Capacity
select 
sum(capacity) as "Total Capacity"
from fact_aggregated_bookings

-- Successful Bookings
select 
sum(successful_bookings) as "Successful Bookings"
from fact_aggregated_bookings

-- Occupancey %
select
concat(cast(sum(successful_bookings)*100.0 / sum(capacity) as int),' %') as "Occupancy %"
from fact_aggregated_bookings

-- Average Rating
select 
avg(ratings_given) as "Average Rating"
from fact_bookings 

-- Total Days
select 
count(dates) as "Total Days"
from dim_date

-- Total Cancelled Bookings
select 
count(*) as 'Total Cancelled Bookings'
from fact_bookings
where booking_status = 'Cancelled'

-- Total Cancelled Bookings %
select
concat(cast(round((count(case when booking_status = 'Cancelled' then 1 end) * 100.0
/ count(*)),0) as int ),'%') as 'Total Cancelled Bookings %'
from fact_bookings

-- Total Checked Out Bookings
select
count(*) as 'Total Checked Out Bookings'
from fact_bookings
where booking_status='Checked Out'


-- Total Checked Out Bookings %
select
concat(cast(round((count(case when booking_status = 'Checked Out' then 1 end) * 100.0
/ count(*)),0) as int ),'%') as 'Total Checked Out Bookings %'
from fact_bookings


-- Total No Shows 
select 
count(*) as 'Total No Shows '
from fact_bookings
where booking_status = 'No Show'

-- Total No Shows %
select 
concat(cast(count(case when booking_status = 'No Show' then 1 end)* 100.0
/ count(*) as int), '%') as 'Total No Show'
from fact_bookings

-- Booking Percentage by Platform
select 
booking_platform as 'Platform',
concat(cast(round(count(booking_id)*100.0/
(select count(*) from fact_bookings) ,0) as int),'%') as 'Booking Percentage'
from fact_bookings
group by booking_platform

-- Booking Percentage by Room class
select 
room_class as 'Room Class',
concat(cast(round(count(booking_id)*100.0/
(select count(*) from fact_bookings),0) as int),'%') as 'Booking Percentage'
from dim_rooms 
join fact_bookings on
dim_rooms.room_id = fact_bookings.room_category
group by room_class

-- Average Daily Rate
select
sum(revenue_realized) / count(booking_id) as 'Average Daily Rate'
from fact_bookings

-- Revenue Per Available Room
select
room_class as 'Room Class',
sum(revenue_realized) 'Total Revenue'
from dim_rooms join fact_bookings
on dim_rooms.room_id=fact_bookings.room_category
group by room_class


-- Daily Booked Room Nights
select 
count(booking_id) / count(distinct(check_in_date)) as 'Total Booking Per Day'
from fact_bookings


-- Daily Sellable Room Nights 
select
sum(capacity) / count(distinct(check_in_date)) as 'Daily Sellable Room Nights '
from fact_aggregated_bookings

-- Daily Utilized Room Nights
select
count(case when booking_status = 'Checked Out' then 1 end) / 
count(distinct(check_in_date)) as 'Daily Utilized Room Nights'
from fact_bookings

-- Revenue Change Week Over Week
select 
concat('Week',DATEPART(WK,check_in_date)) as 'Week No',
sum(revenue_realized) as 'Revenue',
concat(cast(round((((sum(cast(revenue_realized as decimal(10,2)))-
lag(sum(cast(revenue_realized as decimal(10,2))),1,0) 
over (order by datepart(wk,check_in_date))) / nullif(lag(sum(revenue_realized),1,0) over 
(order by datepart (wk,check_in_date)),0))*100.0),0) as int),'%') as 'Revenue Change Week Over Week %'
from fact_bookings
group by datepart(wk,check_in_date)
order by datepart(wk,check_in_date)


-- Occupancy Change Week Over Week
select 
concat('Week',DATEPART(WK,check_in_date)) as 'Week No',
cast(round(sum(successful_bookings)*100.0 / sum(capacity),0) as int) as 'Occupancy %',
concat(cast((cast(sum(successful_bookings)*100.0 / sum(capacity) as decimal(10,2))-
lag(cast(sum(successful_bookings)*100.0 / 
sum(capacity) as decimal(10,2))) over (order by datepart(wk,check_in_date)))/
lag(cast(sum(successful_bookings)*100.0 / 
sum(capacity) as decimal(10,2))) over (order by datepart(wk,check_in_date))* 100 as int),'%')
as 'Occupancy Change Week Over Week %'
from fact_aggregated_bookings
group by datepart(wk,check_in_date)
order by datepart(wk,check_in_date)


-- Average Daily rate Changing Week Over Week %
select 
concat('Week',DATEPART(WK,check_in_date)) as 'Week No',
sum(revenue_realized)/count(booking_id) as 'Average Daily Rate',
concat(cast(round((cast(sum(revenue_realized)/count(booking_id) as decimal(10,2)) -
lag(cast(sum(revenue_realized)/
count(booking_id)as decimal(10,2))) over (order by datepart(wk,check_in_date)))/
lag(cast(sum(revenue_realized)/
count(booking_id)as decimal(10,2))) 
over (order by datepart(wk,check_in_date))*100,0) as int) ,'%') 
as 'Average Daily Rate Change Week Over Week %'
from fact_bookings
group by DATEPART(WK,check_in_date)
order by DATEPART(WK,check_in_date)


-- Revenue Per Available Room Change week over week %
select
concat('Week', DATEPART(WK,check_in_date)) as 'Week No',
room_class as 'Room Class',
sum(revenue_realized) as 'Revenue Generated',
concat(cast((sum(revenue_realized)-
lag(cast(sum(revenue_realized)as decimal(10,2))) 
over(partition by room_class order by 
DATEPART(WK,check_in_date)))/
lag(sum(revenue_realized)) 
over(partition by room_class order by 
DATEPART(WK,check_in_date))*100 as int) ,'%')
as 'Revenue Per Available Room Change week over week %'
from fact_bookings join dim_rooms
on fact_bookings.room_category=dim_rooms.room_id
group by 
DATEPART(WK,check_in_date),
room_class
order by DATEPART(WK,check_in_date)


-- Realisation change percentage week over week %
select
concat('Week', DATEPART(WK,check_in_date)) as 'Week No',
count(case when booking_status='Checked Out' then 1 end) 
as 'Successful Booking',
concat(cast((cast(count(case when booking_status='Checked Out'
then 1 end) as decimal(10,2)) -
lag(count(case when booking_status='Checked Out' then 1 end)) 
over (order by DATEPART(WK,check_in_date)))/
lag(count(case when booking_status='Checked Out' then 1 end)) 
over (order by DATEPART(WK,check_in_date))*100 as int),'%')
as 'Realisation change percentage week over week %'
from fact_bookings
group by DATEPART(WK,check_in_date)
order by DATEPART(WK,check_in_date)


-- Daily Sellable Room Nights Change % week over week
select
concat('Week', DATEPART(WK,check_in_date)) as 'Week No',
sum(successful_bookings) / count(distinct(check_in_date)) 
as 'Rooms Available For Sale',
concat(cast((cast(sum(successful_bookings) / 
count(distinct(check_in_date)) as decimal(10,2))-
lag(sum(successful_bookings) / 
count(distinct(check_in_date))) over 
(order by DATEPART(WK,check_in_date)))/
lag(sum(successful_bookings) / 
count(distinct(check_in_date))) over 
(order by DATEPART(WK,check_in_date)) * 100 as int),'%') 
as "Daily Sellable Room Nights Change % week over week"
from fact_aggregated_bookings
group by DATEPART(WK,check_in_date)
order by DATEPART(WK,check_in_date)