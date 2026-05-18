-- 1.------------------- DATABASE SETUP --------------------

CREATE DATABASE walmart_db;

USE walmart_db;

SELECT * FROM walmart_sales;

-- 2. ---------------------DATA CLEANING -----------------------

#checking for null values
SELECT * FROM walmart_sales
WHERE Store IS NULL 
	OR Date IS NULL
	OR Weekly_sales IS NULL
    OR Holiday_Flag IS NULL
    OR Temperature IS NULL
    OR fuel_price IS NULL
    OR cpi IS NULL
    OR unemployment IS NULL;
	
#check for duplicates
SELECT *,COUNT(*) AS cnt
FROM walmart_sales
GROUP BY Store,
		 Date,
         Weekly_Sales,
         Holiday_Flag,
         Temperature,
         Fuel_Price,
         CPI,
         Unemployment
HAVING cnt > 1;

DESC walmart_sales;

-- 3. --------------------------- convert Date column ----------------------

#create new column
ALTER TABLE walmart_sales
ADD COLUMN new_date DATE;

#convert and insert proper dates
UPDATE walmart_sales
SET new_date = STR_TO_DATE(Date, '%d-%m-%Y');

#Remove old column
ALTER TABLE walmart_sales
DROP COLUMN Date;

#Rename new column
ALTER TABLE walmart_sales
CHANGE new_date Date DATE;

-- 4. -------------------------FEATURE ENGINEERING -----------------------

#Extract Year
ALTER TABLE walmart_sales
ADD COLUMN year INT;

UPDATE walmart_sales
SET year = YEAR(Date);

#Extract month
ALTER TABLE walmart_sales
ADD COLUMN month_days INT;	

UPDATE walmart_sales
SET month_days = MONTH(Date);

#Extract Day name
ALTER TABLE walmart_sales
ADD COLUMN day_name VARCHAR(20);	

UPDATE walmart_sales
SET day_name = DAYNAME(Date);

-- 5.--------------------------BUSINESS ANALYSIS ------------------------

#A. Sales Analysis

#Total Weekly sales
SELECT ROUND(SUM(Weekly_sales), 2) AS total_sales
FROM walmart_sales;

#Average weekly sales
SELECT ROUND(AVG(Weekly_sales), 2) AS avg_sales
FROM walmart_sales;

#Highest sales store
SELECT store, ROUND(SUM(weekly_sales), 2) AS total_sales
FROM walmart_sales
GROUP BY store
ORDER BY total_sales DESC;

#Lowest Sales Store
SELECT Store, ROUND(SUM(weekly_sales), 2) AS total_sales
FROM walmart_sales
GROUP BY Store
ORDER BY total_sales ASC;

#Monthly Sales Trend
SELECT month_days, ROUND(SUM(weekly_sales), 2) AS total_sales
FROM walmart_sales
GROUP BY month_days
ORDER BY total_sales DESC;

#Yearly Sales Trend
SELECT year, ROUND(SUM(weekly_sales), 2) AS total_sales
FROM walmart_sales
GROUP BY year
ORDER BY total_sales DESC;

-- B. --------------------------HOLIDAY ANALYSIS ------------------------

#Holiday vs Non Holiday Sales
SELECT holiday_flag, ROUND(SUM(weekly_sales), 2) AS total_sales
FROM walmart_sales
GROUP BY holiday_flag;

#Average Holiday Sales
SELECT holiday_flag, ROUND(AVG(weekly_sales), 2) AS avg_total_sales
FROM walmart_sales
GROUP BY holiday_flag;

-- C. ------------------------TEMPERATURE ANALYSIS ------------------------------
#Avg Temperature Per Store
SELECT Store, AVG(Temperature) AS avg_temperature
FROM walmart_sales
GROUP BY Store;

#Top 10 Hot Weather High Sales
SELECT Store, Temperature, weekly_sales
FROM walmart_sales
ORDER BY Temperature DESC
LIMIT 10;

-- D. --------------------------FUEL PRICE ANALYSIS -------------------------

#Fuel price impact on sales
SELECT ROUND(AVG(fuel_price), 2) AS fuel_price,
ROUND(AVG(weekly_sales), 2) AS total_sales
FROM walmart_sales;

#Highest Fuel price on weeks
SELECT WEEK(Date) AS weeks, fuel_price
FROM walmart_sales
ORDER BY fuel_price DESC
LIMIT 10;

-- E. ---------------------------ECONOMIC ANALYSIS --------------------------

#CPI vs Sales
SELECT ROUND(CPI,0) AS cpi_range,
       ROUND(AVG(Weekly_Sales),2) AS avg_sales
FROM walmart_sales
GROUP BY cpi_range
ORDER BY cpi_range;

#unemployment impact
SELECT ROUND(unemployment, 2) AS unemployment_rate,
	   ROUND(AVG(weekly_sales), 2) AS avg_sales
FROM walmart_sales
GROUP BY unemployment_rate 
ORDER BY unemployment_rate DESC;

-- 6. ---------------------------WINDOW FUNCTION, CTE -----------------------

#Top 5 sales weeks per store
SELECT * FROM(
SELECT Store, 
	   Date, 
	   weekly_sales, 
       dense_rank() OVER(PARTITION BY Store ORDER BY weekly_sales DESC) AS dnrk
	FROM walmart_sales) AS t
WHERE dnrk <= 5;

#Running Total sales
SELECT Store,
       Date,
       Weekly_Sales,
       SUM(Weekly_Sales)
       OVER(
           PARTITION BY Store
           ORDER BY Date
       ) AS running_sales
FROM walmart_sales;

#CTE Example
WITH sales_cte AS (
    SELECT Store,
           SUM(Weekly_Sales) AS total_sales
    FROM walmart_sales
    GROUP BY Store
)

SELECT *
FROM sales_cte
ORDER BY total_sales DESC;
