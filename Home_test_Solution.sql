-- Question 1: Determine the top 5 artists whose songs appear in the Top 10 of the global_song_rank table the most.

SELECT artist_name, artist_rank
FROM
(
	SELECT 	artist_name,
			DENSE_RANK() OVER(ORDER BY COUNT(global_song_rank.song_id) DESC) AS artist_rank
	FROM artists
	JOIN songs 
		ON artists.artist_id = songs.artist_id
	JOIN global_song_rank 
		ON global_song_rank.song_id = songs.song_id
	WHERE global_song_rank.rank <= 10
	GROUP BY artist_name
) AS abc
WHERE artist_rank <= 5

-- Question 2: Find the lifetime total orders, total spent (GMV), unique items bought , earliest purchase date, last purchased date, average amount spent per order (AOV) and average purchase price (APP) for the following buyer IDs.

SELECT	mot.customer_id, dim.category
		, COUNT(DISTINCT mot.order_id) AS total_orders
		, SUM(mot.price) AS total_spent
		, COUNT(DISTINCT dim.product_id) AS unique_items
		, MIN(mot.order_date) AS earliest_purchased_date
		, MAX(mot.order_date)AS last_purchased_date
		, CEIL(SUM(mot.gmv)/ COUNT(DISTINCT mot.order_id))AS AOV 
		, CEIL(SUM(mot.price)/COUNT(DISTINCT mot.order_id))AS APP 
FROM my_order_trans AS mot
JOIN dim_product AS dim
	ON mot.product_id = dim.product_id
WHERE mot.customer_id IN ('1076216361964070','3190859517651870','3754202390878020')
GROUP BY mot.customer_id, dim.category

-- Question 3: Find out the top 10 cross border items with the highest quantity sold. The output includes minimum selling price, total spent (gmv) and total orders.

SELECT *
FROM
(
	SELECT  dim.product_name
			, dim.category
			, MIN(orders.price) AS min_selling_price
			, SUM(orders.qty_sold) AS total_qty_sold
			, SUM(orders.gmv) AS total_gmv
			, COUNT(DISTINCT orders.order_id) AS total_order
			, DENSE_RANK() OVER(ORDER BY SUM(orders.qty_sold) DESC) AS rank
	FROM my_order_trans AS orders
	JOIN dim_product AS dim 
		ON dim.product_id = orders.product_id
	WHERE is_crossborder = True	
	GROUP BY product_name, category
) abc
WHERE rank <=10

-- Question 4: Find the average time (in day) between their first and second checkout of our customers.

WITH abc AS
(
	SELECT customer_id
			, order_date
			, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) AS order_of_date
	FROM my_order_trans
	GROUP BY customer_id, order_date
),
ghi AS (
	SELECT  distinct_id.customer_id,
		(SELECT order_date FROM abc WHERE abc.customer_id = distinct_id.customer_id AND order_of_date = 1 LIMIT 1) AS first_order,
		(SELECT order_date FROM abc WHERE abc.customer_id = distinct_id.customer_id AND order_of_date = 2 LIMIT 1) AS second_order
	FROM (
		SELECT DISTINCT(customer_id) AS customer_id
		FROM my_order_trans
	) AS distinct_id
)
SELECT 	AVG((DATE_PART('doy', ghi.second_order) - DATE_PART('doy', ghi.first_order))) 
FROM ghi
WHERE second_order IS NOT NULL


