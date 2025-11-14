SELECT*
FROM CAR_SALES
LIMIT 20;

--------------------------------------------------------------------------------------------------
                               ----Explaratory Data Analysis---
                            ---I want to check my categorical columns----
SELECT DISTINCT make
FROM CAR_SALES;

SELECT DISTINCT MODEL
FROM CAR_SALES;

SELECT DISTINCT TRIM
FROM CAR_SALES;

SELECT DISTINCT BODY
FROM CAR_SALES;

SELECT DISTINCT transmission
FROM CAR_SALES;

SELECT DISTINCT vin
FROM CAR_SALES;

SELECT DISTINCT state
FROM CAR_SALES;

SELECT DISTINCT color
FROM CAR_SALES;

SELECT DISTINCT interior
FROM CAR_SALES;

SELECT DISTINCT seller
FROM CAR_SALES;
----------------------------------------------------------------------------------------------------                                            
     SELECT 
     STATE,
     COUNT(*)
     FROM CAR_SALES
     GROUP BY STATE;
     
     SELECT*
     FROM CAR_SALES
     WHERE STATE = '3vwd17aj5fm221322';

     SELECT*
     FROM CAR_SALES
     WHERE LENGTH(STATE)>2;

     SELECT*
     FROM CAR_SALES
     WHERE BODY ='Navitgation';
--------------------------------------------------------------------------------------------------
                         --CHECK DUPLICATES IN CAR_SALES--
SELECT 
    VIN,
    COUNT(*) AS duplicate_count
FROM CAR_SALES
GROUP BY VIN
HAVING COUNT(*) > 1;
---------------------------------------------------------------------------------------------------
                                      -- CHECK NULL COUNTS PER COLUMN
SELECT
    SUM(CASE WHEN VIN IS NULL THEN 1 ELSE 0 END) AS null_vin,
    SUM(CASE WHEN MAKE IS NULL THEN 1 ELSE 0 END) AS null_make,
    SUM(CASE WHEN MODEL IS NULL THEN 1 ELSE 0 END) AS null_model,
    SUM(CASE WHEN TRIM IS NULL THEN 1 ELSE 0 END) AS null_trim,
    SUM(CASE WHEN BODY IS NULL THEN 1 ELSE 0 END) AS null_body,
    SUM(CASE WHEN TRANSMISSION IS NULL THEN 1 ELSE 0 END) AS null_transmission,
    SUM(CASE WHEN VIN IS NULL THEN 1 ELSE 0 END) AS null_vin,
    SUM(CASE WHEN STATE IS NULL THEN 1 ELSE 0 END) AS null_state,
    SUM(CASE WHEN CONDITION IS NULL THEN 1 ELSE 0 END) AS null_condition,
    SUM(CASE WHEN COLOR IS NULL THEN 1 ELSE 0 END) AS null_color,
    SUM(CASE WHEN INTERIOR IS NULL THEN 1 ELSE 0 END) AS null_interior,
    SUM(CASE WHEN SELLER IS NULL THEN 1 ELSE 0 END) AS null_seller,
    SUM(CASE WHEN MMR IS NULL THEN 1 ELSE 0 END) AS null_mmr,
    SUM(CASE WHEN SELLINGPRICE IS NULL THEN 1 ELSE 0 END) AS null_sellingprice,
    SUM(CASE WHEN ODOMETER IS NULL THEN 1 ELSE 0 END) AS null_odometer,
    SUM(CASE WHEN SALEDATE IS NULL THEN 1 ELSE 0 END) AS null_saledate,
    SUM(CASE WHEN YEAR IS NULL THEN 1 ELSE 0 END) AS null_year
FROM CAR_SALES;
----------------------------------------------------------------------------------------------------
             -- REMOVE DUPLICATES (KEEP LATEST SALEDATE)
CREATE OR REPLACE TEMPORARY TABLE CAR_SALES_DEDUPED AS
SELECT *
FROM (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY VIN ORDER BY SALEDATE DESC) AS rn
    FROM CAR_SALES
)
WHERE rn = 1;
--------------------------------------------------------------------------------------------------
                          -- Clean and replace NULLs---
CREATE OR REPLACE TEMPORARY TABLE CAR_SALES_CLEANED AS
SELECT
    VIN,
    COALESCE(MAKE, 'Unknown') AS MAKE,
    COALESCE(MODEL, 'Unknown') AS MODEL,
    COALESCE(TRIM, 'Standard') AS TRIM,
    COALESCE(BODY, 'Unknown') AS BODY,
    COALESCE(TRANSMISSION, 'Unknown') AS TRANSMISSION,
    COALESCE(STATE, 'Unknown') AS REGION,
    COALESCE("CONDITION", 0) AS CAR_CONDITION,  
    COALESCE(COLOR, 'Unknown') AS COLOR,
    COALESCE(INTERIOR, 'Unknown') AS INTERIOR,
    COALESCE(SELLER, 'Unknown') AS SELLER,
    COALESCE(MMR, 0) AS MMR,
    SELLINGPRICE,
    COALESCE(ODOMETER, 0) AS ODOMETER,
    SALEDATE,
    YEAR
FROM CAR_SALES_DEDUPED
WHERE VIN IS NOT NULL
  AND MAKE IS NOT NULL
  AND MODEL IS NOT NULL
  AND SELLINGPRICE IS NOT NULL
  AND SALEDATE IS NOT NULL;
----------------------------------------------------------------------------------------------------                                           
         -- Drop existing temporary table if it exists--
    
    DROP TABLE CAR_SALES_VALID;
------------------------------------------------------------------------------------------------     
         -- Create cleaned and validated table with full date breakdown
                
    CREATE OR REPLACE TEMPORARY TABLE CAR_SALES_VALID AS
    SELECT  
    YEAR AS MANUFACTURER_YEAR,
    MAKE,
    MODEL,
    TRIM,
    BODY AS BODY_TYPE,
    TRANSMISSION,
    VIN,
    REGION,
    CAR_CONDITION,
    COLOR,
    INTERIOR,
    SELLER,
    MMR,
    SELLINGPRICE,
    SALEDATE,

    -- Convert text-based prices (e.g., '15,000') to numeric
    TRY_TO_NUMBER(REPLACE(sellingprice, ',', '')) AS selling_price,
    TRY_TO_NUMBER(REPLACE(mmr, ',', '')) AS cost_price,
    TRY_TO_NUMBER(REPLACE(odometer, ',', '')) AS odometer,

    -- If each row is a single sale, set Units_Sold = 1
    1 AS units_sold,

    -- Calculate Total Revenue
    (TRY_TO_NUMBER(REPLACE(sellingprice, ',', '')) * 1) AS total_revenue,

    -- Calculate Profit Margin (%)
    CASE
        WHEN TRY_TO_NUMBER(REPLACE(sellingprice, ',', '')) > 0 THEN
            ROUND(
                ((TRY_TO_NUMBER(REPLACE(sellingprice, ',', '')) 
                - TRY_TO_NUMBER(REPLACE(mmr, ',', ''))) 
                / TRY_TO_NUMBER(REPLACE(sellingprice, ',', ''))) * 100, 2
            )
        ELSE NULL
    END AS profit_margin,

    -- Categorize cars by Profit Margin tiers
    CASE
        WHEN ROUND(((TRY_TO_NUMBER(REPLACE(sellingprice, ',', '')) 
            - TRY_TO_NUMBER(REPLACE(mmr, ',', ''))) 
            / TRY_TO_NUMBER(REPLACE(sellingprice, ',', ''))) * 100, 2) >= 20 THEN 'High Margin'
        WHEN ROUND(((TRY_TO_NUMBER(REPLACE(sellingprice, ',', '')) 
            - TRY_TO_NUMBER(REPLACE(mmr, ',', ''))) 
            / TRY_TO_NUMBER(REPLACE(sellingprice, ',', ''))) * 100, 2) BETWEEN 10 AND 19.99 THEN 'Medium Margin'
        WHEN ROUND(((TRY_TO_NUMBER(REPLACE(sellingprice, ',', '')) 
            - TRY_TO_NUMBER(REPLACE(mmr, ',', ''))) 
            / TRY_TO_NUMBER(REPLACE(sellingprice, ',', ''))) * 100, 2) < 10 THEN 'Low Margin'
        ELSE 'Unknown'
    END AS performance_tier,

    --  Convert SALEDATE string (e.g., "Wed Jan 21 2015 01:30:00 GMT-0800 (PST)") to TIMESTAMP
    TRY_TO_TIMESTAMP(SUBSTR(SALEDATE, 5, 20), 'MON DD YYYY HH24:MI:SS') AS SALE_TIMESTAMP,

    --  Extract useful date parts
    YEAR(TRY_TO_TIMESTAMP(SUBSTR(SALEDATE, 5, 20), 'MON DD YYYY HH24:MI:SS')) AS SALE_YEAR,
    MONTHNAME(TRY_TO_TIMESTAMP(SUBSTR(SALEDATE, 5, 20), 'MON DD YYYY HH24:MI:SS')) AS SALE_MONTHNAME,
    DAYNAME(TRY_TO_TIMESTAMP(SUBSTR(SALEDATE, 5, 20), 'MON DD YYYY HH24:MI:SS')) AS SALE_DAYNAME,
    QUARTER(TRY_TO_TIMESTAMP(SUBSTR(SALEDATE, 5, 20), 'MON DD YYYY HH24:MI:SS')) AS SALE_QUARTER,

    --  Clean date without time
    TO_DATE(TRY_TO_TIMESTAMP(SUBSTR(SALEDATE, 5, 20), 'MON DD YYYY HH24:MI:SS')) AS SALE_DATE,

       -- TIME without date 
    TO_TIME(TRY_TO_TIMESTAMP(SUBSTR(SALEDATE, 5, 20), 'MON DD YYYY HH24:MI:SS')) AS SALE_TIME,

    --extract time parts
    HOUR(TRY_TO_TIMESTAMP(SUBSTR(SALEDATE, 5, 20), 'MON DD YYYY HH24:MI:SS')) AS SALE_HOUR,

  FROM CAR_SALES_CLEANED
  WHERE BODY != 'Navigation'
  AND MAKE IS NOT NULL
  AND SALEDATE IS NOT NULL
  AND TRY_TO_NUMBER(REPLACE(sellingprice, ',', '')) > 0;

----------------------------------------------------------------------------------------------------
                   -- Final table using GROUP BY all columns--

CREATE OR REPLACE TEMPORARY TABLE CAR_SALES_VALID_FINAL AS
SELECT *
FROM CAR_SALES_VALID
GROUP BY
    MANUFACTURER_YEAR,
    MAKE,
    MODEL,
    TRIM,
    BODY_TYPE,
    TRANSMISSION,
    VIN,
    REGION,
    CAR_CONDITION,
    COLOR,
    INTERIOR,
    SELLER,
    MMR,
    SELLINGPRICE,
    SALEDATE,
    selling_price,
    cost_price,
    odometer,
    units_sold,
    total_revenue,
    profit_margin,
    performance_tier,
    SALE_TIMESTAMP,
    SALE_YEAR,
    SALE_MONTHNAME,
    SALE_DAYNAME,
    SALE_QUARTER,
    SALE_DATE,
    SALE_TIME,
    SALE_HOUR;
---------------------------------------------------------------------------------------------------
                             -- Count of vehicles sold by make and model--
     SELECT MAKE,
            MODEL,
            COUNT(*)
     FROM CAR_SALES_VALID
     GROUP BY MAKE,
              MODEL
     ORDER BY COUNT(*) DESC;
----------------------------------------------------------------------------------------------------------------------------
                                   --Average selling price by state--
     SELECT 
           REGION,
           AVG(SELLING_PRICE) AS AVG_SELLING_PRICE
           FROM CAR_SALES_VALID
           GROUP BY REGION
           ORDER BY AVG_SELLING_PRICE ASC;
----------------------------------------------------------------------------------------------------
              --Preview all converted date columns
SELECT 
    SALEDATE,
    SALE_TIMESTAMP,
    SALE_YEAR,
    SALE_MONTHNAME,
    SALE_DAYNAME,
    SALE_QUARTER,
    SALE_TIME,
    SALE_HOUR
FROM CAR_SALES_VALID
LIMIT 20;
---------------------------------------------------------------------------------------------------
SELECT*
FROM CAR_SALES_VALID;
                ---AVG SELLING PRICE BY YEAR AND MONTH
           SELECT 
                  SALE_YEAR,
                  SALE_MONTH,
           AVG(SELLINGPRICE) AS AVG_SELLING_PRICE
           FROM CAR_SALES_VALID
           GROUP BY SALE_YEAR,
                    SALE_MONTH
           ORDER BY SALE_YEAR,
                    SALE_MONTH;
-----------------------------------------------------------------------------------------------------
                    
                 ---CHECK WHICH MONTH HAD MOST SALES 
           SELECT 
                  SALE_MONTH,
                  COUNT(*)
           FROM CAR_SALES_VALID
           GROUP BY SALE_MONTH
           ORDER BY  SALE_MONTH ASC;
-----------------------------------------------------------------------------------------------------

                ---CHECK THE EMPTY VALUE OF MONTHNAME
           SELECT 
                  SALE_MONTHNAME,
                  COUNT(*)
           FROM CAR_SALES_VALID
           GROUP BY SALE_MONTHNAME
----------------------------------------------------------------------------------------------------
          SELECT *
          FROM CAR_SALES_VALID
          WHERE SALE_MONTHNAME  IS NULL OR SALE_MONTHNAME ='';
-----------------------------------------------------------------------------------------------------         
                      ---MOST SELLING MODELS WITHIN EACH BODY TYPE---
          SELECT
                MAKE, MODEL,BODY_TYPE,BODY_RANK
          FROM (
                SELECT MAKE,MODEL,BODY_TYPE,COUNT(*) AS NUM_SALES,
                RANK() OVER (PARTITION BY  BODY_TYPE ORDER BY COUNT(*) DESC) AS BODY_RANK
          FROM CAR_SALES_VALID
          GROUP BY MAKE,MODEL,BODY_TYPE
          )
          WHERE BODY_RANK <=5;
----------------------------------------------------------------------------------------------------
                ----CHECK ALL TABLES------
         SELECT*
         FROM CAR_SALES_VALID_FINAL;

         
         SELECT REGION
         FROM CAR_SALES_VALID_FINAL;

         

----------------------------------------------------------------------------------------------------         
          

           


                                                            

     
