/*	Question Set 1 - Easy */

-- Q1: Who is the senior most employee based on job title?

SELECT * FROM employee
ORDER BY levels desc
limit 1;


-- Q2: Which countries has the most invoices?

SELECT billing_country, COUNT(billing_country) as MostInvoices FROM invoice
GROUP BY billing_country
ORDER BY Mostinvoices desc
limit 1;


-- Q3: What are the top 3 values of total invoice?

SELECT total FROM invoice
order by total desc
limit 3;


/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

SELECT billing_city, SUM(total) as InvoiceTotal
FROM invoice
GROUP BY billing_city
ORDER BY InvoiceTotal desc;


/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

SELECT cus.customer_id, cus.first_name, cus.last_name, SUM(inv.total) as Total_Amount_Spent
FROM customer as cus
JOIN invoice as inv
ON cus.customer_id = inv.customer_id
GROUP BY cus.customer_id
ORDER BY Total_Amount_Spent desc
LIMIT 1;



/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

SELECT DISTINCT first_name, last_name, email
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN (
					SELECT track_id FROM track
					JOIN genre ON track.genre_id = genre.genre_id
					WHERE genre.name LIKE 'Rock'
)
ORDER BY email;



/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

SELECT artist.artist_id, artist.name, COUNT(artist.artist_id) as number_of_songs 
FROM artist
JOIN album ON artist.artist_id = album.artist_id
JOIN track ON album.album_id = track.album_id
JOIN genre ON track.genre_id = genre.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY number_of_songs desc
limit 10;


/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

SELECT name, milliseconds as song_length
FROM track
WHERE milliseconds > (
					 SELECT AVG(milliseconds)
					 FROM track
)
ORDER BY milliseconds desc
limit 10;



/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */

WITH best_selling_artist AS (
	 SELECT artist.artist_id as artist_id, artist.name as artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) as total_sales 
	 FROM invoice_line
	 JOIN track on invoice_line.track_id = track.track_id
	 JOIN album on track.album_id = album.album_id
	 JOIN artist on album.artist_id = artist.artist_id
	 GROUP BY 1
	 ORDER BY 3 desc
	 LIMIT 1
)
SELECT cs.customer_id, cs.first_name, cs.last_name, bsa.artist_name, SUM(inl.unit_price*inl.quantity) as total_sales 
FROM customer cs 
JOIN invoice inv ON cs.customer_id = inv.customer_id
JOIN invoice_line inl ON inv.invoice_id = inl.invoice_id
JOIN track tr ON inl.track_id = tr.track_id
JOIN album al ON tr.album_id = al.album_id
JOIN best_selling_artist bsa ON al.artist_id = bsa.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 desc



/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */


-- Using CTE
WITH popular_genre AS (
	SELECT COUNT(invoice_line.quantity) as purchases, customer.country, genre.name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) as RowNo
	FROM invoice_line
	JOIN invoice ON invoice_line.invoice_id = invoice.invoice_id
	JOIN customer ON invoice.customer_id = customer.customer_id
	JOIN track ON invoice_line.track_id = track.track_id
	JOIN genre ON track.genre_id = genre.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <=1


-- Using Recursive
WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2)
		
SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;



/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

-- Using CTE
WITH customer_with_country AS (
	SELECT customer.customer_id, first_name, last_name, billing_country, SUM(total) as total_spending,
	ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) as RowNo
	FROM invoice
	JOIN customer ON invoice.customer_id = customer.customer_id
	GROUP BY 1,2,3,4
	ORDER BY 4 ASC, 5 DESC
) 
SELECT * FROM customer_with_country WHERE RowNo <=1


