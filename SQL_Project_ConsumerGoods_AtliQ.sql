####################SQL Project#################

# TASK 1 -  Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
SELECT DISTINCT market FROM dim_customer
WHERE customer = "Atliq Exclusive" AND region = "APAC";

#Task2 - What is the percentage of unique product increase in 2021 vs. 2020? The
/*final output contains these fields: unique_products_2020 , unique_products_2021 , percentage_chg*/
WITH cte AS (
	SELECT (SELECT COUNT(DISTINCT product_code) FROM fact_sales_monthly WHERE fiscal_year = 2021) AS unique_product_2021 , 
		   (SELECT COUNT(DISTINCT product_code) FROM fact_sales_monthly WHERE fiscal_year = 2020) AS unique_product_2020
)
SELECT *,ROUND(((unique_product_2021/unique_product_2020) -1)*100.0,2) AS percentage_chg FROM cte;

/*TASK 3: Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains 2 fields : (segment and product_count)*/
SELECT segment , COUNT(product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

/*TASK 4 - Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
The final output contains these fields: (segment , product_count_2020 , product_count_2021 , difference)*/
WITH cte1 AS (
	SELECT p.segment , COUNT(DISTINCT f.product_code) AS product_count_2021
	FROM dim_product p 
	JOIN fact_sales_monthly f
		ON f.product_code = p.product_code
	WHERE f.fiscal_year = 2021
	GROUP BY segment),
    cte2 AS (
	SELECT p.segment , COUNT(DISTINCT f.product_code) AS product_count_2020
	FROM dim_product p 
	JOIN fact_sales_monthly f
		ON f.product_code = p.product_code
	WHERE f.fiscal_year = 2020
	GROUP BY segment)
SELECT segment , product_count_2020 , product_count_2021 , product_count_2021 - product_count_2020 AS difference
FROM cte1
JOIN cte2
	USING (segment)
ORDER BY difference DESC;

/*Task 5 Get the products that have the highest and lowest manufacturing costs.The final output should contain these fields:
(product_code , product , manufacturing_cost)*/
SELECT f.product_code , p.product , MAX(f.manufacturing_cost)
FROM fact_manufacturing_cost f
JOIN dim_product p
	ON p.product_code = f.product_code
UNION
SELECT f.product_code , p.product , MIN(f.manufacturing_cost)
FROM fact_manufacturing_cost f
JOIN dim_product p
	ON p.product_code = f.product_code;
    
/* task 6 -Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct 
for the fiscal year 2021 and in the Indian market. The final output contains these fields: 
(customer_code , customer , average_discount_percentage)*/
SELECT f.customer_code , c.customer , AVG(f.pre_invoice_discount_pct)*100.0 AS average_discount_percentage
FROM fact_pre_invoice_deductions f
JOIN dim_customer c
	ON c.customer_code = f.customer_code
WHERE f.fiscal_year = 2021 AND c.market = "India"
GROUP BY f.customer_code
ORDER BY average_discount_percentage DESC
LIMIT 5;

/*TASK 7: Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This 
analysis helps to get an idea of low and high-performing months and take strategic decisions. The final report contains 
these columns: (Month , Year , Gross sales Amount)*/
SELECT 
	CONCAT(MONTHNAME(fs.date),"(",YEAR(fs.date),")") AS Month , 
    fs.fiscal_year,
    ROUND(SUM(fg.gross_price * fs.sold_quantity)/1000000,2) AS Gross_sales_amount_in_million
FROM fact_sales_monthly fs
JOIN fact_gross_price   fg
	ON fg.fiscal_year = fs.fiscal_year AND fg.product_code = fs.product_code
JOIN dim_customer c
	ON c.customer_code = fs.customer_code
WHERE c.customer = "Atliq Exclusive"
GROUP BY Month(fs.date) , fs.fiscal_year
ORDER BY fiscal_year;


/*Task 8:In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields: (Quarter , total_sold_quantity). Output is sorted by total_sold_quantity
WITH cte AS (
	SELECT *,
	CONCAT("Q",CEIL(MONTH(DATE_ADD(date, INTERVAL 4 MONTH))/3)) AS quarter 
    FROM fact_sales_monthly)
SELECT quarter , SUM(sold_quantity) AS total_sold_quantity
FROM cte
WHERE fiscal_year = 2020
GROUP BY quarter 
ORDER by total_sold_quantity DESC;


/*TASK 9:Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields: (channel , gross_sales_mln , percentage)*/
WITH cte AS ( 
	SELECT c.channel , ROUND(SUM(s.sold_quantity * g.gross_price)/1000000,2) AS gross_sales_mln 
	FROM fact_sales_monthly s
	JOIN fact_gross_price   g 
		ON s.product_code = g.product_code AND s.fiscal_year = g.fiscal_year
	JOIN dim_customer       c
		ON c.customer_code = s.customer_code
	WHERE s.fiscal_year = 2021
	GROUP BY c.channel )
SELECT channel , gross_sales_mln , gross_sales_mln/(SELECT SUM(gross_sales_mln) FROM cte) * 100.0  AS percentage
FROM cte
ORDER BY gross_sales_mln DESC;


/*Task 10: Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields : division , product_code , product , total_sold_quantity , rank_order*/
WITH cte1 AS (
	SELECT p.division , p.product_code , CONCAT(p.product ,"-", p.variant) AS product , 
    SUM(s.sold_quantity) total_sold_quantity
	FROM fact_sales_monthly s
	JOIN dim_product        p
		ON p.product_code = s.product_code
	WHERE s.fiscal_year = 2021
	GROUP BY p.division , p.product_code ),
	cte2 AS (
    SELECT * , dense_rank() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order 
    FROM cte1)
SELECT * FROM cte2 
WHERE rank_order <= 3;




           



