# SQL Data Cleaning Project – Cafe Sales Dataset

## Overview
This project showcases the end-to-end cleaning of a raw cafe sales dataset using SQL. The data contained inconsistent column names, placeholder values like 'ERROR' or 'UNKNOWN', invalid data types, and logical inconsistencies in calculated fields.

The goal was to transform this data into a clean, analysis-ready table suitable for exploratory analysis.

---

## Cleaning Steps Performed
- Metadata validation for easier queries and understandability 
- Check if we can impute invalid placeholders with duplicates with the valid values
- Impute invalid placeholders with NULL
- Converted `total_spent` from text to numeric after ensuring it matched `quantity × price_per_unit` and meeting the business logical consistency
- Converted `transaction_date` to proper DATE format after checking mismatches
- Validated that `transaction_id` is unique (acts as a primary key)
- Checked for logical errors (e.g., future dates, zero quantities)
- Nulls ratio per column

---

## Tools Used
- SQL (MySQL)
---

## Summary of Cleaning Impact

| Field             | Issue Detected                  | Fix Applied              | Affected Rows |
|------------------|----------------------------------|--------------------------|---------------|
| item             | 'ERROR', '', 'UNKNOWN'           | Set to NULL              | 859           |
| payment_method   | Same as above                    | Set to NULL              | 2847          |
| location         | Same as above                    | Set to NULL              | 3564          |
| total_spent      | Wrong value or invalid format    | Recalculated & cast      | 462           |
| transaction_date | Non-date formats or future dates | Recast & filtered        | 410           |

---

## Final Output
The cleaned dataset is stored in a table called `cafe_sales_cleaned`. It’s now suitable for Exploratory data analysis


