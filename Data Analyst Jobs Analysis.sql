-- 1.	How many rows are in the data_analyst_jobs table?
--1793
SELECT COUNT (title) AS total_jobs
FROM data_analyst_jobs;

-- 2.	Write a query to look at just the first 10 rows. What company is associated with the job posting on the 10th row?
-- ExxonMobil
SELECT *
FROM data_analyst_jobs
LIMIT 10;

SELECT *
FROM data_analyst_jobs
LIMIT 1 OFFSET 9;

-- 3.	How many postings are in Tennessee? How many are there in either Tennessee or Kentucky?
-- 21
-- 27

SELECT COUNT (*) as TN_jobs
FROM data_analyst_jobs
WHERE location = 'TN';

SELECT COUNT (*) AS TN_KY_jobs
FROM data_analyst_jobs
WHERE location = 'TN'
OR location = 'KY';

-- 4.	How many postings in Tennessee have a star rating above 4?
-- 416
SELECT COUNT (star_rating) AS over_4_stars
from data_analyst_jobs
where star_rating > 4;

-- 5.	How many postings in the dataset have a review count between 500 and 1000?
-- 151
SELECT COUNT (title) AS reviews_between_500_1000
FROM data_analyst_jobs
WHERE review_count >= 500
AND review_count <= 1000;

-- 6.	Show the average star rating for companies in each state. The output should show the state as `state` and the average rating for the state as `avg_rating`. Which state shows the highest average rating?
--NE

SELECT location AS state, AVG(star_rating) AS avg_rating
FROM data_analyst_jobs
WHERE star_rating IS NOT NULL
GROUP BY location
ORDER BY avg_rating DESC;

SELECT location AS state, AVG(star_rating) AS avg_rating
FROM data_analyst_jobs
WHERE star_rating IS NOT NULL
GROUP BY location
ORDER BY avg_rating DESC
LIMIT 1;

-- 7.	Select unique job titles from the data_analyst_jobs table. How many are there?
-- 881
SELECT DISTINCT title
FROM data_analyst_jobs;

SELECT COUNT(DISTINCT title) AS distinct_title_count
FROM data_analyst_jobs;

-- 8.	How many unique job titles are there for California companies?
-- 230

SELECT COUNT(DISTINCT title) AS distinct_title_count_cali
FROM data_analyst_jobs
WHERE location = 'CA';

-- 9.	Find the name of each company and its average star rating for all companies that have more than 5000 reviews across all locations. How many companies are there with more that 5000 reviews across all locations?
SELECT comapny, AVG(star_rating) AS avg_star_rating
FROM data_analyst_jobs
WHERE review_count > 5000
GROUP BY comapny;

SELECT location, COUNT(comapny) AS company_count
FROM data_analyst_jobs
WHERE review_count > 5000
AND comapny IS NOT NULL
GROUP BY location
ORDER BY company_count DESC;

-- 10.	Add the code to order the query in #9 from highest to lowest average star rating. Which company with more than 5000 reviews across all locations in the dataset has the highest star rating? What is that rating?
--highest star rating 4.2

SELECT comapny, AVG(star_rating) AS avg_star_rating
FROM data_analyst_jobs
WHERE review_count > 5000
GROUP BY comapny
ORDER BY avg_star_rating DESC;


-- 11.	Find all the job titles that contain the word ‘Analyst’. How many different job titles are there? 
--1789
SELECT title
FROM data_analyst_jobs
WHERE title LIKE '%analyst%'
OR title LIKE '%analytics%';

SELECT COUNT (title) AS contains_analyst
FROM data_analyst_jobs
WHERE title ILIKE '%analyst%'
OR title ILIKE '%analytics%';



SELECT COUNT (DISTINCT title) AS contains_analyst
FROM data_analyst_jobs
WHERE title ILIKE '%analyst%'
OR title ILIKE '%analytics%';

-- 12.	How many different job titles do not contain either the word ‘Analyst’ or the word ‘Analytics’? 

SELECT COUNT (title) AS NOT_analyst_count
FROM data_analyst_jobs
WHERE title NOT ILIKE '%analyst%'
AND title NOT ILIKE '%analytics%';

-- 4

SELECT (title) AS NOT_analyst_count
FROM data_analyst_jobs
WHERE title NOT ILIKE '%analyst%'
AND title NOT ILIKE '%analytics%';

-- What word do these positions have in common?
-- Tableau

-- **BONUS:**
-- You want to understand which jobs requiring SQL are hard to fill. Find the number of jobs by industry (domain) that require SQL and have been posted longer than 3 weeks. 
--  - Disregard any postings where the domain is NULL. 
--  - Order your results so that the domain with the greatest number of `hard to fill` jobs is at the top. 

SELECT domain, COUNT(title) AS sql_jobs
FROM data_analyst_jobs
  WHERE domain IS NOT NULL
  AND days_since_posting > 21
  AND skill LIKE '%SQL%'
GROUP BY domain
ORDER BY sql_jobs DESC;

--   - Which three industries are in the top 4 on this list? 
SELECT domain, COUNT(title) AS sql_jobs
FROM data_analyst_jobs
  WHERE domain IS NOT NULL
  AND skill LIKE '%SQL%'
GROUP BY domain
ORDER BY sql_jobs DESC
LIMIT 4;

-- "Internet and Software"
-- "Banks and Financial Services"
-- "Consulting and Business Services"
-- "Health Care"

-- How many jobs have been listed for more than 3 weeks for each of the top 4?
SELECT domain, COUNT(title) AS sql_jobs
FROM data_analyst_jobs
  WHERE days_since_posting > 21
  AND domain IS NOT NULL
  AND skill LIKE '%SQL%'
GROUP BY domain
ORDER BY sql_jobs DESC
LIMIT 4;


