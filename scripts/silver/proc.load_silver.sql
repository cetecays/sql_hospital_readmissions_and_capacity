/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to
    populate the 'silver' schema tables from the 'bronze' schema.
    Actions Performed:
        - Truncates Silver tables.
        - Inserts transformed and cleansed data from Bronze into Silver tables.

Parameters:
    None.
      This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS 
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		PRINT '===========================================';
		PRINT 'Loading Silver Layer';
		PRINT '===========================================';

		PRINT '-------------------------------------------'
		PRINT 'Loading Hospital Operations Dataset'
		PRINT '-------------------------------------------'

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.hospital_operations_dataset';
		TRUNCATE TABLE silver.hospital_operations_dataset;

		PRINT '>> Inserting data into: silver.hospital_operations_dataset';
		INSERT INTO silver.hospital_operations_dataset (
			hod_patient_id,
			hod_visit_date,
			hod_age,
			hod_gender,
			hod_disease,
			hod_severity,
			hod_admission,
			hod_length_of_stay,
			hod_bed_required,
			hod_icu_required,
			hod_oxygen_required,
			hod_ventilator_required,
			hod_total_beds_available,
			hod_beds_occupied,
			hod_icu_beds_available,
			hod_icu_beds_occupied,
			hod_oxygen_units_used,
			hod_month,
			hod_season,
			hod_day_of_week,
			hod_department,
			hod_readmission_within_30_days
			)
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
			) AS hod_visit_date, -- Standardise Visit Date Formatting and Convert to DATE Data Type
			TRY_CONVERT(int, hod_age) AS hod_age,
			TRIM(hod_gender) AS hod_gender,
			hod_disease,
			TRIM(hod_severity) AS hod_severity,
			TRIM(hod_admission) AS hod_admission,
			TRY_CONVERT(int, hod_length_of_stay) AS hod_length_of_stay,
			hod_bed_required,
			hod_icu_required,
			hod_oxygen_required,
			hod_ventilator_required,
			TRY_CONVERT(int, hod_total_beds_available) AS hod_total_beds_available,
			TRY_CONVERT(int, hod_beds_occupied) AS hod_beds_occupied,
			TRY_CONVERT(int, hod_icu_beds_available) AS hod_icu_beds_available,
			TRY_CONVERT(int, hod_icu_beds_occupied) AS hod_icu_beds_occupied,
			TRY_CONVERT(int, hod_oxygen_units_used) AS hod_oxygen_units_used,
			TRY_CONVERT(int, hod_month) AS hod_month,
			hod_season,
			DATENAME(WEEKDAY, (COALESCE(
									TRY_CONVERT(date, hod_visit_date, 23),
									TRY_CONVERT(date, hod_visit_date, 103),
									TRY_CONVERT(date, hod_visit_date, 101),
									TRY_CONVERT(date, hod_visit_date, 105),
									TRY_CONVERT(date, hod_visit_date, 112),
									TRY_CONVERT(date, hod_visit_date, 106),
									TRY_CONVERT(date, hod_visit_date)
								))) AS hod_day_of_week, -- Correct matching of day of week with hod_visit_date
			TRIM(hod_department) AS hod_department,
			TRIM(hod_readmission_within_30_days) AS hod_readmission_within_30_days
		FROM (
            SELECT
                *,
                ROW_NUMBER() OVER (PARTITION BY hod_patient_id, hod_visit_date ORDER BY hod_patient_id DESC) AS flag_last
            FROM bronze.hospital_operations_dataset
            WHERE hod_patient_id IS NOT NULL
        ) t
        WHERE flag_last = 1 -- Remove duplicate records
		AND TRY_CONVERT(int, hod_age) <= 110 -- Remove age outliers
		AND TRY_CONVERT(int, hod_oxygen_units_used) <= 97 -- Remove hod_oxygen_units_used outliers
		AND TRY_CONVERT(int, hod_length_of_stay) <= 17.5 -- Remove hod_length_of_stay outliers
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
	END TRY
	BEGIN CATCH
		PRINT '==========================================='
		PRINT 'ERROR OCCURED WHILE LOADING SILVER LAYER'
		PRINT 'Error Message: ' + ERROR_MESSAGE();
		PRINT 'Error Message: ' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message: ' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '==========================================='
	END CATCH
END
