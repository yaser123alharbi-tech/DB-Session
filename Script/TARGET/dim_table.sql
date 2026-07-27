CREATE SCHEMA IF NOT EXISTS TARGET;


-- Dimension tables:

CREATE table IF NOT EXISTS TARGET.country_dim (

country_key SERIAL PRIMARY KEY,
country_code VARCHAR(10) UNIQUE,
country_name VARCHAR(100),
region VARCHAR(100)
);

CREATE table IF NOT EXISTS TARGET.customer_dim (

customer_key SERIAL PRIMARY KEY,
customer_id VARCHAR(20) UNIQUE,
customer_name VARCHAR(150),
country_code VARCHAR(50),
customer_type VARCHAR(50)
);

CREATE table IF NOT EXISTS TARGET.product_dim (

product_key SERIAL PRIMARY KEY,
product_id VARCHAR(20) UNIQUE,
product_name VARCHAR(150),
category VARCHAR(50),
standard_price numeric(12,2)
);

