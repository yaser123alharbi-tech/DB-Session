-- INSERTING VALEUS INTO THE TABLES

TRUNCATE TABLE bronze.country RESTART IDENTITY CASCADE;
TRUNCATE TABLE bronze.customer RESTART IDENTITY CASCADE;
TRUNCATE TABLE bronze.product RESTART IDENTITY CASCADE;
TRUNCATE TABLE bronze.sales_transactions RESTART IDENTITY CASCADE;


COPY bronze.country(country_code, country_name, region)
FROM 'D:\Rihal DB\country.csv'
DELIMITER ','
CSV HEADER;

COPY bronze.customer
FROM 'D:\Rihal DB\customer.csv'
DELIMITER ','
CSV HEADER;

COPY bronze.product
FROM 'D:\Rihal DB\product.csv'
DELIMITER ','
CSV HEADER;

COPY bronze.sales_transactions
FROM 'D:\Rihal DB\sales_transactions.csv'
DELIMITER ','
CSV HEADER;

