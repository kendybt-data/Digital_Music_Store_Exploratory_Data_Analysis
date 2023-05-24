/* SQL PROJECT - DIGITAL MUSIC STORE EXPLORATORY DATA ANALYSIS by KENDY BRONCANO */

/* ------ Exploring Tables ---------*/
SELECT * FROM album;
SELECT * FROM artist;
SELECT * FROM customer;
SELECT * FROM employee;
SELECT * FROM genre;
SELECT * FROM invoice;
SELECT * FROM invoice_line;
SELECT * FROM media_type;
SELECT * FROM playlist;
SELECT * FROM playlist_track;
SELECT * FROM track;

/* ------ Answer Questions - QUERYS ---------*/

/* ------ Questions - Set 1 ---------*/

/* 1. Who is the most senior employee? */
SELECT *
FROM employee
ORDER BY hire_date
LIMIT 1;

/* 2. Which countries have the most invoices? */
SELECT billing_country, COUNT(*) AS TOTAL_NUMBER_INVOICES
FROM invoice
GROUP BY billing_country
ORDER BY 2 DESC;

/* 3. What are top 3 values of total invoice? */
SELECT total
FROM invoice
ORDER BY total DESC
LIMIT 3;

/* 4. Which city has the best customers? We would like to organize a 
	  promotional Music Festival in the city where we have made the most 
	  money. Write a query that returns a city that has the highest sum 
	  of invoice totals. Return both the name of the city and the sum of 
	  all invoice totals. */
SELECT billing_city, ROUND(SUM(total)::NUMERIC,2) AS SUM_INVOICE_TOTAL
FROM invoice
GROUP BY billing_city
ORDER BY 2 DESC
LIMIT 1;

/* 5. Who is the best customer? The customer who has spent the most money 
	  will be declared the best customer. Write a query that returns the 
	  person who has spent the most money. */
SELECT i.customer_id, c.first_name, c.last_name,
ROUND(SUM(i.total)::NUMERIC,2) AS TOTAL_SPENT
FROM invoice i
JOIN customer c
ON i.customer_id = c.customer_id
GROUP BY i.customer_id, c.first_name, c.last_name
ORDER BY 4 DESC
LIMIT 1;


/* ------ Questions - Set 2 ---------*/

/* 1. Write a query to get the email, first name, last name and genre 
	  of all rock music listeners. Return the list sorted alphabetically 
	  by email starting with A. */
SELECT DISTINCT c.email, c.first_name, c.last_name, g.name AS GENRE_NAME
FROM customer c
JOIN invoice i
ON c.customer_id = i.customer_id
JOIN invoice_line l
ON i.invoice_id = l.invoice_id
JOIN track t
ON l.track_id = t.track_id
JOIN genre g
ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
ORDER BY c.email;

/* 2. Let's invite the artists who have written the most rock music in our 
	  dataset. Write a query that returns the Artist name and total track 
	  count of the top 10 rock bands */
SELECT a.name AS ARTIST_NAME, g.name AS GENRE_NAME, COUNT(t.name) AS TOTAL_TRACKS 
FROM artist a
JOIN album b
ON a.artist_id = b.artist_id
JOIN track t
ON b.album_id = t.album_id
JOIN genre g
ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
GROUP BY ARTIST_NAME, GENRE_NAME
ORDER BY 3 DESC
LIMIT 10;

/* 3. Returns all track names that have a song duration greater than the 
	  average song duration. Returns the name and milliseconds of each song. 
	  Sort by song length with the longest songs first. */
SELECT name as NAME_TRACK, milliseconds
FROM track
WHERE milliseconds > (SELECT AVG(milliseconds) 
					  FROM track)
ORDER BY milliseconds DESC;


/* ------ Questions - Set 3 ---------*/

/* 1. How much did each customer spend on the top-selling artist? Write a 
	  query that returns the customer name, artist name, and total spent */
WITH SUB AS (
	SELECT a.artist_id, a.name, ROUND(SUM(l.unit_price*l.quantity)::NUMERIC,2)
	FROM invoice_line l
	JOIN track t
	ON l.track_id = t.track_id
	JOIN album b
	ON t.album_id = b.album_id
	JOIN artist a
	ON b.artist_id = a.artist_id
	GROUP BY 1,2
	ORDER BY 3 DESC
	LIMIT 1)

SELECT (c.first_name || ' ' || c.last_name) AS CUSTOMER_NAME, a.name AS ARTIST_NAME, 
ROUND(SUM(l.unit_price*l.quantity)::NUMERIC,2) AS TOTAL_SPENT 
FROM customer c
JOIN invoice i
ON c.customer_id = i.customer_id
JOIN invoice_line l
ON i.invoice_id = l.invoice_id
JOIN track t
ON l.track_id = t.track_id
JOIN album b
ON t.album_id = b.album_id
JOIN artist a
ON b.artist_id = a.artist_id
WHERE a.name = (SELECT name FROM SUB)
GROUP BY CUSTOMER_NAME, ARTIST_NAME
ORDER BY 3 DESC;

/* 2. We want to find out what is the most popular music genre for each 
	  country. We determine the most popular genre as the genre with the 
	  highest number of purchases. Write a query that returns each country 
	  along with the Most Popular Genre. */
WITH SUB AS (
	SELECT c.country, g.name, SUM(l.quantity) AS NUMBER_PURCHASES,
	ROW_NUMBER() OVER (PARTITION BY c.country ORDER BY SUM(l.quantity) DESC)
	AS ORDER_BY_COUNTRY
	FROM genre g
	JOIN track t
	ON g.genre_id = t.genre_id
	JOIN invoice_line l
	ON t.track_id = l.track_id
	JOIN invoice i
	ON l.invoice_id = i.invoice_id
	JOIN customer c
	ON i.customer_id = c.customer_id
	GROUP BY 1,2
	ORDER BY 1,3 DESC)

SELECT country, name, NUMBER_PURCHASES
FROM SUB
WHERE ORDER_BY_COUNTRY = 1
ORDER BY 3 DESC;

/* 3. Write a query that determines the customer who has spent the most 
	  on music for each country. Write a query that returns the country 
	  along with the customer who spent the most and how much they spent. */
WITH SUB AS (
	SELECT i.billing_country, (c.first_name || ' ' || c.last_name) AS CUSTOMER_NAME, 
	ROUND(SUM(i.total)::NUMERIC,2) AS TOTAL_SPENT,
	ROW_NUMBER() OVER (PARTITION BY i.billing_country ORDER BY SUM(i.total) DESC) 
	AS ORDER_BY_COUNTRY
	FROM customer c
	JOIN invoice i
	ON c.customer_id = i.customer_id
	GROUP BY 1,2
	ORDER BY 1,3 DESC)

SELECT billing_country, CUSTOMER_NAME, TOTAL_SPENT
FROM SUB 
WHERE ORDER_BY_COUNTRY = 1
ORDER BY 3 DESC;