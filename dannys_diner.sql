CREATE database dannys_diner;
use dannys_diner;
CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ("A", "2021-01-01", 1),
  ("A", "2021-01-01", 2),
  ("A", "2021-01-07", 2),
  ("A", "2021-01-10", 3),
  ("A", "2021-01-11", 3),
  ("A", "2021-01-11", 3),
  ("B", "2021-01-01", 2),
  ("B", "2021-01-02", 2),
  ("B", "2021-01-04", 1),
  ("B", "2021-01-11", 1),
  ("B", "2021-01-16", 3),
  ("B", "2021-02-01", 3),
  ("C", "2021-01-01", 3),
  ("C", "2021-01-01", 3),
  ("C", "2021-01-07", 3);
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  (1, "sushi", 10),
  (2, "curry", 15),
  (3, "ramen", 12);
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ("A", "2021-01-07"),
  ("B", "2021-01-09");
  
  /* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
select customer_id, sum(m.price) as total_amt
from sales s inner join menu m using(product_id)
group by 1;

-- 2. How many days has each customer visited the restaurant?
select customer_id, count(*) as days_visited
from sales
group by 1;

-- 3. What was the first item from the menu purchased by each customer?
with first_item as(select distinct s.customer_id,m.product_name, s.order_date, 
                  dense_rank() over(partition by customer_id order by order_date asc) as firsts
from sales s inner join menu m using(product_id))
select customer_id, product_name 
from first_item 
where firsts =1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select product_id, product_name, count(product_id) as noof_times_purchased
from sales inner join menu using(product_id)
group by 1,2
order by 3 desc
limit 1;

-- 5. Which item was the most popular for each customer?
with popular as(
select s.customer_id, m.product_name, count(*) as number_of_orders, 
                dense_rank() over(partition by customer_id order by count(*) desc) as ranks
from sales s inner join menu m using(product_id)
group by 1,2
)
select customer_id, product_name
from popular
where ranks=1;

-- 6. Which item was purchased first by the customer after they became a member?
with purchased as(
select s.customer_id, m.product_name,s.product_id, row_number() over(partition by customer_id order by s.order_date) as row_num
from members inner join sales s using (customer_id) inner join menu m using(product_id)
where order_date> join_date
)
SELECT 
  customer_id, 
  product_name 
FROM purchased
WHERE row_num = 1
ORDER BY customer_id ASC;

-- 7. Which item was purchased just before the customer became a member?
with cm as(
select s.customer_id, m.product_name,s.product_id, rank() over(partition by customer_id order by s.order_date desc) as rnk
from members left join sales s using (customer_id) inner join menu m using(product_id)
where order_date< join_date
)
SELECT 
  customer_id, 
  product_name 
FROM cm
WHERE rnk = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
select s.customer_id, count(*) as total_items, sum(price) as amt_spent
from members inner join sales s using (customer_id) inner join menu m using(product_id)
where order_date< join_date
group by 1
order by 1;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with point as(select customer_id, product_name,price,if(product_name="sushi", price*20, price*10) as total_points
from sales s inner join menu m using(product_id))
select customer_id, sum(total_points) as points
from point
group by 1;

/*10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
 not just sushi - how many points do customer A and B have at the end of January?*/
with point as(select * ,case 
     when order_date- join_date>=0 and order_date-join_date<=6 then (price*20)
     when product_name = "sushi" then price*20
     else price*10
     end as points
from sales inner join members using (customer_id) inner join menu using (product_id)   
where month(order_date)= 01)
select customer_id, sum(points) as totalpoints
from point
group by 1
order by 1; 

  