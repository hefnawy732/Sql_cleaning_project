CREATE SCHEMA cleaning_project;
USE cleaning_project;

-- A glance at the data
SELECT * FROM dirty_cafe_sales LIMIT 10;

-- 1. Creating replica to keep our raw source intact
CREATE TABLE cafe_sales_replica AS SELECT * FROM dirty_cafe_sales;
SELECT * FROM cafe_sales_replica LIMIT 10;

-- 2. Metadata Validation: Changing the names of the columns to make it easier for queries
ALTER TABLE cafe_sales_replica 
RENAME COLUMN `Transaction ID` TO `transaction_id`,
RENAME COLUMN `Item` TO `item`,
RENAME COLUMN `Quantity` TO `quantity`,
RENAME COLUMN `Price Per Unit` TO `price_per_unit`,
RENAME COLUMN `Total Spent` TO `total_spent`,
RENAME COLUMN `Payment Method` TO `payment_method`,
RENAME COLUMN `Location` TO `location`,
RENAME COLUMN `Transaction Date` TO `transaction_date`;

-- 3. Data Type Validation: Changing data types
ALTER TABLE cafe_sales_replica
MODIFY COLUMN transaction_id varchar(50),
MODIFY COLUMN item varchar(50),
MODIFY COLUMN quantity TINYINT UNSIGNED,
MODIFY COLUMN price_per_unit DECIMAL(10,2),
MODIFY COLUMN payment_method varchar(50),
MODIFY COLUMN location varchar(50);

	-- 3.1 Data Type Validation: For the column total_spent, it's in text, as there are some columns named 'ERROR', We have to impute that before converting.
SELECT total_spent, COUNT(*) as num_of_occurances
FROM cafe_sales_replica
GROUP BY 1;

    -- 3.2 Data Type Validation: For the column total_spent before changing data type.
SELECT total_spent, COUNT(*) as num_of_mismatches
FROM cafe_sales_replica
WHERE total_spent != quantity * price_per_unit OR total_spent < 0
GROUP BY 1;

	-- For making sure we're getting non-negative as a result for total_spent, 0 Records found
SELECT *
FROM cafe_sales_replica
WHERE quantity <= 0 OR price_per_unit <= 0;

	-- 3.3 Data Type Validation: Let's convert the old column with the cleaned one
UPDATE cafe_sales_replica
SET total_spent = (quantity * price_per_unit);
ALTER TABLE cafe_sales_replica MODIFY COLUMN total_spent DECIMAL(10,2);

SELECT *
FROM cafe_sales_replica
WHERE total_spent != quantity * price_per_unit OR total_spent < 0;

	-- 3.3 Data Type Validation: For the transaction_date, Let's make it in date_formate
SELECT transaction_date, COUNT(*) as num_of_mismatches
FROM cafe_sales_replica
WHERE transaction_date NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
GROUP BY 1;

	-- 3.4 Data Type Validation: For the transaction_date, Handling Empty strings, 'ERROR', 'UNKNOWN' values found 
    -- No actual dates found in different formates to handle.
UPDATE cafe_sales_replica
SET transaction_date = NULL 
WHERE transaction_date NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';

	-- 3.5 Data Type Validation: For the transaction_date, Updating the data type
ALTER TABLE cafe_sales_replica MODIFY COLUMN transaction_date DATE;

-- 4. Pattern and nulls
SELECT item, COUNT(*) as num_of_occurances
FROM cafe_sales_replica
GROUP BY 1;

	/* 4.1 Pattern and nulls for 'item', Checking if there's a complete record of the same row where item's value is valid
	   We're running this to check if transaction_id was repeated
	   We cannot exclude transaction_id and run comparison between rest of the columns, Because there's no customer_id, Nor datetime "Only date"
	   So, even if there are duplicates across columns except 'Item'
 	   we cannot rely on that for imputation, as Muliple orders might share the exact same details on the same date normally */
SELECT t1.item, t2.item
FROM cafe_sales_replica t1
JOIN cafe_sales_replica t2
  ON t1.transaction_id = t2.transaction_id
WHERE 
    (t1.item IS NULL OR t1.item IN ('', 'ERROR', 'UNKNOWN'))
  AND ( t2.item IS NOT NULL AND t2.item NOT IN ('', 'ERROR', 'UNKNOWN'));

	-- 4.2 Pattern and nulls for 'item', No complete duplicates, We'd impute by null
UPDATE cafe_sales_replica
SET item = NULL
WHERE item IN ('', 'ERROR', 'UNKNOWN');

	/* 4.3 Pattern and nulls for 'payment_method', Checking if there's a complete record of the same row where payment_method's value is valid
	   We're running this to check if transaction_id was repeated
	   We cannot exclude transaction_id and run comparison between rest of the columns, Because there's no customer_id, Nor datetime "Only date"
	   So, even if there are duplicates across columns except 'payment_method'
 	   we cannot rely on that for imputation, as Muliple orders might share the exact same details on the same date normally */

SELECT payment_method, COUNT(*) as num_of_occurances
FROM cafe_sales_replica
GROUP BY 1;

SELECT t1.payment_method, t2.payment_method
FROM cafe_sales_replica t1
JOIN cafe_sales_replica t2
 ON t1.transaction_id = t2.transaction_id
WHERE 
    (t1.payment_method IS NULL OR t1.payment_method IN ('', 'ERROR', 'UNKNOWN'))
  AND ( t2.payment_method IS NOT NULL AND t2.payment_method NOT IN ('', 'ERROR', 'UNKNOWN'));

	-- 4.4 Pattern and nulls for 'payment_method', No complete duplicates, We'd impute by null
UPDATE cafe_sales_replica
SET payment_method = NULL
WHERE payment_method IN ('', 'ERROR', 'UNKNOWN');

	/* 4.5 Pattern and nulls for 'location', Checking if there's a complete record of the same row where location's value is valid
	   We're running this to check if transaction_id was repeated
	   We cannot exclude transaction_id and run comparison between rest of the columns, Because there's no customer_id, Nor datetime "Only date"
	   So, even if there are duplicates across columns except 'location'
 	   we cannot rely on that for imputation, as Muliple orders might share the exact same details on the same date normally */

SELECT location, COUNT(*) as num_of_occurances
FROM cafe_sales_replica
GROUP BY 1;

SELECT t1.location, t2.location
FROM cafe_sales_replica t1
JOIN cafe_sales_replica t2
 ON t1.transaction_id = t2.transaction_id
WHERE 
    (t1.location IS NULL OR t1.location IN ('', 'ERROR', 'UNKNOWN'))
  AND ( t2.location IS NOT NULL AND t2.location NOT IN ('', 'ERROR', 'UNKNOWN'));
  
	-- 4.6 Pattern and nulls for 'location', No complete duplicates, We'd impute by null
UPDATE cafe_sales_replica
SET location = NULL
WHERE location IN ('', 'ERROR', 'UNKNOWN');


-- 5 Checking duplicates, transaction_id is unique and indeed the PK, no duplicates
SELECT transaction_id, COUNT(*) as num_of_occurances
FROM cafe_sales_replica
GROUP BY 1
HAVING COUNT(*)>1;
-- Since the date we got is showing date only not datetime, Then we wouldn't be able to check duplicates of the row content aside from the PK
-- It might happen that on the same date, same location, same item is purchased in the same quantity etc.

-- 6. Logical consistency 
SELECT *
FROM cafe_sales_replica
WHERE transaction_date > CURDATE();

-- 7. Nulls ratio per column
SELECT 
  COUNT(*) AS total_rows,
  ROUND(100 * SUM(transaction_id IS NULL) / COUNT(*), 2) AS pct_null_transaction_id,
  ROUND(100 * SUM(item IS NULL) / COUNT(*), 2) AS pct_null_item,
  ROUND(100 * SUM(quantity IS NULL) / COUNT(*), 2) AS pct_null_quantity,
  ROUND(100 * SUM(price_per_unit IS NULL) / COUNT(*), 2) AS pct_null_price,
  ROUND(100 * SUM(total_spent IS NULL) / COUNT(*), 2) AS pct_null_total_spent,
  ROUND(100 * SUM(payment_method IS NULL) / COUNT(*), 2) AS pct_null_payment_method,
  ROUND(100 * SUM(location IS NULL) / COUNT(*), 2) AS pct_null_location,
  ROUND(100 * SUM(transaction_date IS NULL) / COUNT(*), 2) AS pct_null_transaction_date
FROM cafe_sales_replica;

-- 8. The final cleaned table
CREATE TABLE cafe_sales_cleaned AS
SELECT * FROM cafe_sales_replica;


