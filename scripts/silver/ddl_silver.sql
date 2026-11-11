/*
===============================================================================
DDL Script: Create Silver Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'silver' schema, dropping existing tables
    if they already exist.
      Run this script to re-define the DDL structure of 'silver' Tables
===============================================================================
*/

IF OBJECT_ID ('silver.hospital_operations_dataset', 'U') IS NOT NULL
	DROP TABLE silver.hospital_operations_dataset;

CREATE TABLE silver.hospital_operations_dataset (
	hod_patient_id NVARCHAR(MAX),
	hod_visit_date NVARCHAR(MAX),
	hod_age NVARCHAR(MAX),
	hod_gender NVARCHAR(MAX),
	hod_disease NVARCHAR(MAX),
	hod_severity NVARCHAR(MAX),
	hod_admission NVARCHAR(MAX),
	hod_length_of_stay NVARCHAR(MAX),
	hod_bed_required NVARCHAR(MAX),
	hod_icu_required NVARCHAR(MAX),
	hod_oxygen_required NVARCHAR(MAX),
	hod_ventilator_required NVARCHAR(MAX),
	hod_total_beds_available NVARCHAR(MAX),
	hod_beds_occupied NVARCHAR(MAX),
	hod_icu_beds_available NVARCHAR(MAX),
	hod_ice_beds_occupied NVARCHAR(MAX),
	hod_oxygen_units_used NVARCHAR(MAX),
	hod_month NVARCHAR(MAX),
	hod_season NVARCHAR(MAX),
	hod_day_of_week NVARCHAR(MAX),
	hod_department NVARCHAR(MAX),
	hod_readmission_within_30_days NVARCHAR(MAX)
);
