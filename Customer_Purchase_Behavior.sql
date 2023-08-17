CREATE SCHEMA dannys_diner;

CREATE TABLE dannys_diner.sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO dannys_diner.sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE dannys_diner.menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO dannys_diner.menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE dannys_diner.members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO dannys_diner.members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
-- 1. What is the total amount each customer spent at the restaurant?
select 
	s.customer_id,
    sum(menu.price) as Sales
from
	dannys_diner.sales as s
join dannys_diner.menu as menu on s.product_id = menu.product_id
group by customer_id

-- 2. How many days has each customer visited the restaurant?
select s.customer_id, count(distinct s.order_date) as Number_of_visit
from dannys_diner.sales as s
group by s.customer_id

-- 3. What was the first item from the menu purchased by each customer?
WITH customer_first_date AS (
    SELECT s.customer_id AS customer_id, MIN(s.order_date) AS first_order_date
    FROM dannys_diner.sales AS s
    GROUP BY s.customer_id
)
SELECT 
    cfd.customer_id, cfd.first_order_date, menu.product_name
FROM customer_first_date AS cfd
JOIN dannys_diner.sales AS s ON cfd.customer_id = s.customer_id
    AND cfd.first_order_date = s.order_date
JOIN dannys_diner.menu AS menu ON s.product_id = menu.product_id;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select menu.product_name as product_name, count(*) as total_purchase
from dannys_diner.menu as menu
join dannys_diner.sales as sales 
on menu.product_id = sales.product_id
group by product_name
order by total_purchase desc
limit 1;

-- 5. Which item was the most popular for each customer?
With customer_popularity as (
	select sales.customer_id, menu.product_name, count(*) as total_purchase,
		row_number() over(partition by sales.customer_id order by count(*) desc) as most_purchase
	from dannys_diner.sales as sales 
	join dannys_diner.menu as menu
	on sales.product_id = menu.product_id
	group by 1,2
)

select *
from customer_popularity 
where most_purchase = 1
-- 6. Which item was purchased first by the customer after they became a member?
with customer_first_date_as_member as (
	select
		sales.customer_id, min(sales.order_date) as the_first_order_date_as_member
	from dannys_diner.members as m
	join dannys_diner.sales as sales
	on m.customer_id = sales.customer_id
    where sales.order_date > m.join_date
	group by 1
)
select 
	cfdam.customer_id, menu.product_name
from customer_first_date_as_member as cfdam
join dannys_diner.sales as sales
on cfdam.customer_id = sales.customer_id
and cfdam.the_first_order_date_as_member = sales.order_date
join dannys_diner.menu as menu
on sales.product_id = menu.product_id;
-- 7. Which item was purchased just before the customer became a member?
with cte as(
	select 
		sales.customer_id, max(sales.order_date) as the_first_purchase_date
	from dannys_diner.sales as sales
	join dannys_diner.members as mb using (customer_id)
	where sales.order_date < mb.join_date
    group by 1
)

select 
	cte.customer_id, menu.product_name
from cte 
join dannys_diner.sales as sales
on sales.customer_id = cte.customer_id
and sales.order_date = cte.the_first_purchase_date
join dannys_diner.menu as menu 
on sales.product_id = menu.product_id;
-- 8. What is the total items and amount spent for each member before they became a member?
select
	sales.customer_id, count(*) as total_items, sum(m.price) as total_spent
from dannys_diner.sales as sales
join dannys_diner.menu as m
	on sales.product_id = m.product_id
join dannys_diner.members as mb
	on sales.customer_id = mb.customer_id
where mb.join_date > sales.order_date
group by 1
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select 
	s.customer_id, sum(
		case when m.product_name = 'sushi' then m.price*20
        else m.price*10 end) as total_points
from dannys_diner.sales as s
join dannys_diner.menu as m on s.product_id = m.product_id
group by 1
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
select
	s.customer_id, sum(
    case
		when s.order_date between mb.join_date and date_add(mb.join_date, interval 7 day)
        then m.price*20
        when m.product_name = 'sushi' then m.price*20
        else m.price*10 end) as total_points
from dannys_diner.sales s
join dannys_diner.menu m on s.product_id = m.product_id
left join dannys_diner.members as mb on s.customer_id = mb.customer_id
where s.customer_id in ('A','B') and s.order_date < '2021-01-31'
group by 1
  
-- 11. Recreate the table output using the available data
select
	s.customer_id, s.order_date, m.product_name, m.price,
    case when s.order_date >= mb.join_date then 'Y'
    else 'N' end as member
from dannys_diner.sales s
join dannys_diner.menu m on s.product_id = m.product_id
left join dannys_diner.members as mb on s.customer_id = mb.customer_id
order by s.customer_id, s.order_date