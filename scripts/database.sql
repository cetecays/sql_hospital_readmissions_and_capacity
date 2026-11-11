/*
==================================================================
Create Database and Schemas
==================================================================
Script Purpose:
  This script creates a new database named 'DataWarehouse' after checking if it already exists.
  If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas
  within the database: 'bronze', 'silver' and 'gold'.

WARNING:
  Running this script will drop the entire 'DataWarehouse' database if it exists.
  All data in the database will be permanently deleted. Proceed with caution and
  ensure you have proper backups before runnign this script.
*/

USE master;
GO

-- Drop and recreate the 'ReadmissionCapacity_DataWarehouse' Database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'ReadmissionCapacity_DataWarehouse')
BEGIN
  ALTER DATABASE ReadmissionCapacity_DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
  DROP DATABASE ReadmissionCapacity_DataWarehouse;
END;
GO

-- Create the 'ReadmissionCapacity_DataWarehouse' database
CREATE DATABASE ReadmissionCapacity_DataWarehouse;
GO

USE ReadmissionCapacity_DataWarehouse;
GO

CREATE SCHEMA bronze;
GO
  
CREATE SCHEMA silver;
GO
  
CREATE SCHEMA gold;
