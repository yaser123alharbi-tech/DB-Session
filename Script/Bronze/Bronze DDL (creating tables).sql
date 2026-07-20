CREATE TABLE bronze.customer (
    customer_id VARCHAR(10) PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    country_code VARCHAR(5),
    customer_type VARCHAR(50)
);

CREATE TABLE bronze.product (
    product_id VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    standard_price NUMERIC(10,2)
);

CREATE TABLE bronze.sales_transactions (
    transaction_id INTEGER PRIMARY KEY,
    transaction_date DATE NOT NULL,
    customer_id VARCHAR(10) NOT NULL,
    product_id VARCHAR(10) NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL,
    total_amount NUMERIC(10,2) NOT NULL,
    payment_mode VARCHAR(20),

    CONSTRAINT fk_customer
        FOREIGN KEY (customer_id)
        REFERENCES bronze.customer(customer_id),

    CONSTRAINT fk_product
        FOREIGN KEY (product_id)
        REFERENCES bronze.product(product_id)
);

CREATE TABLE bronze.country (
    country_code VARCHAR(10) PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL,
    region VARCHAR(100)
);

