/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy,
    and standardization across the 'silver' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- Check for unwanted spaces
-- Expectation: No Result
DECLARE @sql_space_hod NVARCHAR(MAX);

SELECT @sql_space_hod = STRING_AGG(
    CAST(
        'SELECT ' + QUOTENAME(COLUMN_NAME, '''') +
        ' AS column_name, ' +
        QUOTENAME(COLUMN_NAME) +
        ' AS column_value ' +
        'FROM silver.hospital_operations_dataset ' +
        'WHERE ' + QUOTENAME(COLUMN_NAME) +
        ' != TRIM(' + QUOTENAME(COLUMN_NAME) + ')'
        AS NVARCHAR(MAX)
    ),
    ' UNION ALL '
)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'silver'
  AND TABLE_NAME = 'hospital_operations_dataset';

EXEC sp_executesql @sql_space_hod;

-- Data Standardisation & Consistency
DECLARE @sql_standardise_hod NVARCHAR(MAX);

SELECT @sql_standardise_hod = STRING_AGG(
    CAST(
        'SELECT DISTINCT
            ''' + COLUMN_NAME + ''' AS column_name,
            CAST([' + COLUMN_NAME + '] AS NVARCHAR(MAX)) AS distinct_value
        FROM silver.hospital_operations_dataset'
        AS NVARCHAR(MAX)
    ),
    ' UNION ALL '
)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'silver'
AND TABLE_NAME = 'hospital_operations_dataset'
AND COLUMN_NAME NOT IN (
'hod_patient_id','hod_visit_date','hod_age','hod_length_of_stay','hod_total_beds_available','hod_beds_occupied','hod_icu_beds_available','hod_icu_beds_occupied','hod_oxygen_units_used');

EXEC sp_executesql @sql_standardise_hod;

-- Check for inconsistent date formatting
SELECT
hod_visit_date
FROM silver.hospital_operations_dataset
WHERE hod_visit_date NOT LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]';

SELECT
hod_patient_id,
COALESCE(
	TRY_CONVERT(date, hod_visit_date, 23),
	TRY_CONVERT(date, hod_visit_date, 103),
	TRY_CONVERT(date, hod_visit_date, 101),
	TRY_CONVERT(date, hod_visit_date, 105),
	TRY_CONVERT(date, hod_visit_date, 112),
	TRY_CONVERT(date, hod_visit_date, 106),
	TRY_CONVERT(date, hod_visit_date)
) AS hod_visit_date
FROM silver.hospital_operations_dataset

-- Check for Visit Date Mismatch with Date of Week
SELECT
hod_patient_id,
hod_visit_date_clean,
hod_day_of_week
FROM (SELECT 
    hod_patient_id,
    COALESCE(
	    TRY_CONVERT(date, hod_visit_date, 23),
	    TRY_CONVERT(date, hod_visit_date, 103),
	    TRY_CONVERT(date, hod_visit_date, 101),
	    TRY_CONVERT(date, hod_visit_date, 105),
	    TRY_CONVERT(date, hod_visit_date, 112),
	    TRY_CONVERT(date, hod_visit_date, 106),
	    TRY_CONVERT(date, hod_visit_date)
    ) AS hod_visit_date_clean,
    hod_day_of_week
    FROM silver.hospital_operations_dataset) a
WHERE DATENAME(WEEKDAY, hod_visit_date_clean) != hod_day_of_week

SELECT
	DATENAME(WEEKDAY, (COALESCE(
						    TRY_CONVERT(date, hod_visit_date, 23),
						    TRY_CONVERT(date, hod_visit_date, 103),
						    TRY_CONVERT(date, hod_visit_date, 101),
						    TRY_CONVERT(date, hod_visit_date, 105),
						    TRY_CONVERT(date, hod_visit_date, 112),
						    TRY_CONVERT(date, hod_visit_date, 106),
						    TRY_CONVERT(date, hod_visit_date)
					    ))) AS hod_day_of_week
FROM silver.hospital_operations_dataset;

-- Check for NULLs or Negative Numbers
DECLARE @hod_TableName NVARCHAR(128) = 'hospital_operations_dataset';
DECLARE @hod_SchemaName NVARCHAR(128) = 'silver';
DECLARE @hod_SQL NVARCHAR(MAX) = '';

SELECT @hod_SQL = STRING_AGG(
    CAST(
        'SELECT
            ''' + COLUMN_NAME + ''' AS column_name,
            COUNT(CASE WHEN ' + QUOTENAME(COLUMN_NAME) + ' IS NULL
                  THEN 1 END) AS null_count,
            COUNT(CASE WHEN TRY_CONVERT(DECIMAL(38,10), '
                + QUOTENAME(COLUMN_NAME) + ') < 0
                  THEN 1 END) AS negative_count
         FROM ' + QUOTENAME(@hod_SchemaName) + '.' + QUOTENAME(@hod_TableName)
        AS NVARCHAR(MAX)
    ),
    ' UNION ALL '
)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = @hod_SchemaName
  AND TABLE_NAME = @hod_TableName;

EXEC sp_executesql @hod_SQL;

--Check whether capacity is appropriately recorded
SELECT *
FROM silver.hospital_operations_dataset a
LEFT JOIN (SELECT 
    hod_patient_id,
    COALESCE(
	    TRY_CONVERT(date, hod_visit_date, 23),
	    TRY_CONVERT(date, hod_visit_date, 103),
	    TRY_CONVERT(date, hod_visit_date, 101),
	    TRY_CONVERT(date, hod_visit_date, 105),
	    TRY_CONVERT(date, hod_visit_date, 112),
	    TRY_CONVERT(date, hod_visit_date, 106),
	    TRY_CONVERT(date, hod_visit_date)
    ) AS hod_visit_date_clean
    FROM silver.hospital_operations_dataset) b ON a.hod_patient_id = b.hod_patient_id
ORDER BY b.hod_visit_date_clean ASC;

-- Check for duplicates in primary key
SELECT hod_patient_id,
hod_visit_date_clean,
COUNT(*)
FROM (SELECT
hod_patient_id,
COALESCE(
	TRY_CONVERT(date, hod_visit_date, 23),
	TRY_CONVERT(date, hod_visit_date, 103),
	TRY_CONVERT(date, hod_visit_date, 101),
	TRY_CONVERT(date, hod_visit_date, 105),
	TRY_CONVERT(date, hod_visit_date, 112),
	TRY_CONVERT(date, hod_visit_date, 106),
	TRY_CONVERT(date, hod_visit_date)
) AS hod_visit_date_clean,
hod_age 
FROM silver.hospital_operations_dataset) AS a
GROUP BY hod_patient_id, hod_visit_date_clean
HAVING COUNT(*) > 1

-- Check for age outliers
SELECT
    hod_patient_id,
    hod_age
FROM silver.hospital_operations_dataset
WHERE TRY_CONVERT(int, hod_age) < 0
   OR TRY_CONVERT(int, hod_age) >= 110;

-- Check for other outliers (hod_length_of_stay)
WITH converted AS (
    SELECT
        hod_patient_id,
        hod_length_of_stay,
        TRY_CONVERT(int, hod_length_of_stay) AS length_of_stay_value
    FROM silver.hospital_operations_dataset
),

quartiles AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.25)
            WITHIN GROUP (ORDER BY length_of_stay_value)
            OVER () AS q1,

        PERCENTILE_CONT(0.75)
            WITHIN GROUP (ORDER BY length_of_stay_value)
            OVER () AS q3
    FROM converted
    WHERE length_of_stay_value IS NOT NULL
),

bounds AS (
    SELECT
        q1,
        q3,
        q3 - q1 AS iqr,
        q1 - 1.5 * (q3 - q1) AS lower_bound,
        q3 + 1.5 * (q3 - q1) AS upper_bound
    FROM quartiles
)

SELECT
    c.hod_patient_id,
    c.hod_length_of_stay,
    c.length_of_stay_value,
    b.lower_bound,
    b.upper_bound
FROM converted AS c
CROSS JOIN bounds AS b
WHERE c.length_of_stay_value < b.lower_bound
   OR c.length_of_stay_value > b.upper_bound
ORDER BY c.length_of_stay_value;

-- Check for other outliers (hod_oxygen_units_used)
WITH converted AS (
    SELECT
        hod_patient_id,
        hod_oxygen_units_used,
        TRY_CONVERT(int, hod_oxygen_units_used) AS oxygen_units_used_value
    FROM silver.hospital_operations_dataset
),

quartiles AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.25)
            WITHIN GROUP (ORDER BY oxygen_units_used_value)
            OVER () AS q1,

        PERCENTILE_CONT(0.75)
            WITHIN GROUP (ORDER BY oxygen_units_used_value)
            OVER () AS q3
    FROM converted
    WHERE oxygen_units_used_value IS NOT NULL
),

bounds AS (
    SELECT
        q1,
        q3,
        q3 - q1 AS iqr,
        q1 - 1.5 * (q3 - q1) AS lower_bound,
        q3 + 1.5 * (q3 - q1) AS upper_bound
    FROM quartiles
)

SELECT
    c.hod_patient_id,
    c.hod_oxygen_units_used,
    c.oxygen_units_used_value,
    b.lower_bound,
    b.upper_bound
FROM converted AS c
CROSS JOIN bounds AS b
WHERE c.oxygen_units_used_value < b.lower_bound
   OR c.oxygen_units_used_value > b.upper_bound
ORDER BY c.oxygen_units_used_value;

-- Check for Out-of-range Dates
SELECT
hod_patient_id,
hod_visit_date_clean
FROM (
SELECT
hod_patient_id,
COALESCE(
	TRY_CONVERT(date, hod_visit_date, 23),
	TRY_CONVERT(date, hod_visit_date, 103),
	TRY_CONVERT(date, hod_visit_date, 101),
	TRY_CONVERT(date, hod_visit_date, 105),
	TRY_CONVERT(date, hod_visit_date, 112),
	TRY_CONVERT(date, hod_visit_date, 106),
	TRY_CONVERT(date, hod_visit_date)
) AS hod_visit_date_clean
FROM silver.hospital_operations_dataset) a
WHERE hod_visit_date_clean < '2023-01-01' OR hod_visit_date_clean > '2024-12-31'
