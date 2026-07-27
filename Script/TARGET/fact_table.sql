-- CREATE Fact table for Sales Transactions

CREATE TABLE IF NOT EXISTS TARGET.Sales_Transactions_Fact (
    Sales_Trans_Key    SERIAL PRIMARY KEY,
    transaction_id     INTEGER,
    transaction_date   DATE,
    customer_id        VARCHAR(20),
    product_id         VARCHAR(20),
    quantity           INTEGER,
    unit_price         NUMERIC(12,2),
    total_amount       NUMERIC(12,2),
    payment_mode       VARCHAR(30),
    Country_Key        INTEGER REFERENCES TARGET.Country_Dim(Country_Key),
    Customer_Key       INTEGER REFERENCES TARGET.Customer_Dim(Customer_Key),
    Product_Key        INTEGER REFERENCES TARGET.Product_Dim(Product_Key)