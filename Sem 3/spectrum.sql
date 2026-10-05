/* How does Redshift run queries using serverless redshift spectrum to pull data from external S3 Data Lakes?

1. Leader node parses the query and optimizes it tp generate an execution plan
2. It pushes the execution plan to the Redshift Spectrum Fleet , a massive pool of  compute instances separate from your redshift cluster
3. Partition and Column Pruning: a) Using AWS Glue Data Catalog metadata, the unneeded folders are skipped to inspect the S3 structure; b) since files are stored in Parquet format, reads the specific columns only
4. Filters and aggregates data : File scanning, decompression, predicate filtering (WHERE clause) and partial aggregation over S3.
5. Final Aggregation: Only vastly reduced result set is sent ovber high-speed AWS networking backend to your Redshoft cluster for final joins and formatting


_______________________________________

How to setup Redshift Spectrum (production DDL)?
1. Setup an external schema pointing at AWS Glue data Catalog
2. Setup external table pointing to the S3 Parquet data
*/

-- Step 1: Create ext schema

CREATE EXTERNAL SCHEMA spectrum_schema
FROM DATA CATALOG
DATABASE 'analytics_db'
IAM ROLE 'arn:aws:iam::123456789012:role/RedshiftSpectrumRole'
CREATE EXTERNAL DATABASE IF NOT EXISTS;

-- Step 2: Create ext table

CREATE EXTERNAL TABLE spectrum_schema.ext_table(
	cust_id INT,
	sales_id INT,
	sales_amt NUMERIC(6,2)
)
PARTITIONED BY (year INT, month INT)
STORED AS PARQUET
LOCATION 's3://my-company-datalake/sales/';


-- Step 3: Query S3 Parquet data seamlessly alongside local tables

SELECT 
	cust_id,
	SUM(sales_amt) AS total
	FROM spectrum_schema.ext_table s
	JOIN SSS t
	ON s.sales_id = t.sales_id
	WHERE t.year = 2006
	AND t.month = 08
	GROUP BY cust_id;
