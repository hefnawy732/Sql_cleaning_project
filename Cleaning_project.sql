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
SELECT *
FROM cafe_sales_replica
WHERE total_spent != quantity * price_per_unit;

	-- 3.3 Data Type Validation: Let's convert the old column with the cleaned one
UPDATE cafe_sales_replica
SET total_spent = (quantity * price_per_unit);
ALTER TABLE cafe_sales_replica MODIFY COLUMN total_spent DECIMAL(10,2);

SELECT *
FROM cafe_sales_replica
WHERE total_spent != quantity * price_per_unit;

	-- 3.3 Data Type Validation: For the transaction_date, Let's make it in date_formate
SELECT DISTINCT transaction_date
FROM cafe_sales_replica
WHERE transaction_date NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';

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

	-- 4.1 Pattern and nulls for 'item', Checking if there's a complete record of the same row where item's value is valid
SELECT t1.item, t2.item
FROM cafe_sales_replica t1
JOIN cafe_sales_replica t2
  ON t1.transaction_id = t2.transaction_id
 AND t1.quantity = t2.quantity
 AND t1.price_per_unit = t2.price_per_unit
 AND t1.total_spent = t2.total_spent
 AND t1.payment_method = t2.payment_method
 AND t1.location = t2.location
 AND t1.transaction_date = t2.transaction_date
WHERE 
  (
    t1.item IS NULL 
    OR t1.item = '' 
    OR t1.item = 'ERROR' 
    OR t1.item = 'UNKNOWN'
  )
  AND (
    t2.item IS NOT NULL 
    AND t2.item != '' 
    AND t2.item != 'ERROR' 
    AND t2.item != 'UNKNOWN'
  );

	-- 4.2 Pattern and nulls for 'item', No complete duplicates, We'd impute by null
UPDATE cafe_sales_replica
SET item = NULL
WHERE item = 'ERROR'
OR item = 'UNKNOWN'
OR item = '';

	-- 4.3 Pattern and nulls for 'payment_method', Checking if there's a complete record of the same row where method's value is valid
SELECT payment_method, COUNT(*) as num_of_occurances
FROM cafe_sales_replica
GROUP BY 1;

SELECT t1.payment_method, t2.payment_method
FROM cafe_sales_replica t1
JOIN cafe_sales_replica t2
  ON t1.transaction_id = t2.transaction_id
  AND t1.item = t2.item
 AND t1.quantity = t2.quantity
 AND t1.price_per_unit = t2.price_per_unit
 AND t1.total_spent = t2.total_spent
 AND t1.location = t2.location
 AND t1.transaction_date = t2.transaction_date
WHERE 
  (
    t1.payment_method IS NULL 
    OR t1.payment_method = '' 
    OR t1.payment_method = 'ERROR' 
    OR t1.payment_method = 'UNKNOWN'
  )
  AND (
    t2.payment_method IS NOT NULL 
    AND t2.payment_method != '' 
    AND t2.payment_method != 'ERROR' 
    AND t2.payment_method != 'UNKNOWN'
  );

	-- 4.4 Pattern and nulls for 'payment_method', No complete duplicates, We'd impute by null
UPDATE cafe_sales_replica
SET payment_method = NULL
WHERE payment_method = 'ERROR'
OR payment_method = 'UNKNOWN'
OR payment_method = '';

-- 4.5 Pattern and nulls for 'location', Checking if there's a complete record of the same row where location's value is valid
SELECT location, COUNT(*) as num_of_occurances
FROM cafe_sales_replica
GROUP BY 1;

SELECT t1.location, t2.location
FROM cafe_sales_replica t1
JOIN cafe_sales_replica t2
  ON t1.transaction_id = t2.transaction_id
  AND t1.item = t2.item
 AND t1.quantity = t2.quantity
 AND t1.price_per_unit = t2.price_per_unit
 AND t1.total_spent = t2.total_spent
 AND t1.payment_method = t2.payment_method
 AND t1.transaction_date = t2.transaction_date
WHERE 
  (
    t1.location IS NULL 
    OR t1.location = '' 
    OR t1.location = 'ERROR' 
    OR t1.location = 'UNKNOWN'
  )
  AND (
    t2.location IS NOT NULL 
    AND t2.location != '' 
    AND t2.location != 'ERROR' 
    AND t2.location != 'UNKNOWN'
  );
  
	-- 4.6 Pattern and nulls for 'location', No complete duplicates, We'd impute by null
UPDATE cafe_sales_replica
SET location = NULL
WHERE location = 'ERROR'
OR location = 'UNKNOWN'
OR location = '';


-- 5 Checking duplicates, transaction_id is unique and indeed the PK, no duplicates
SELECT transaction_id, COUNT(*) as num_of_occurances
FROM cafe_sales_replica
GROUP BY 1
HAVING COUNT(*)>1;
-- Since the date we got is showing date only not datetime, Then we wouldn't be able to check duplicates of the row content aside from the PK
-- It might happen that on the same date, same location, same item is purchased in the same quantity etc.

-- 6 Logical consistency 
SELECT *
FROM cafe_sales_replica
WHERE transaction_date > CURDATE();


