TRUNCATE TABLE TARGET.Sales_Transactions_Fact;
TRUNCATE TABLE TARGET.Country_Dim, TARGET.Customer_Dim, TARGET.Product_Dim CASCADE;

INSERT INTO TARGET.Country_Dim (country_code, country_name, region)
SELECT country_code, country_name, region
FROM bronze.country;
 
INSERT INTO TARGET.Customer_Dim (customer_id, customer_name, country_code, customer_type)
SELECT customer_id, customer_name, country_code, customer_type
FROM bronze.customer;
 
INSERT INTO TARGET.Product_Dim (product_id, product_name, category, standard_price)
SELECT product_id, product_name, category, standard_price
FROM bronze.product;


INSERT INTO TARGET.Sales_Transactions_Fact (
    transaction_id, transaction_date, customer_id, product_id,
    quantity, unit_price, total_amount, payment_mode,
    Country_Key, Customer_Key, Product_Key
)



SELECT
    s.transaction_id,
    s.transaction_date,
    s.customer_id,
    s.product_id,
    s.quantity,
    s.unit_price,
    s.total_amount,
    s.payment_mode,
    ctry.Country_Key,
    cust.Customer_Key,
    prod.Product_Key
FROM bronze.sales_transactions s
JOIN bronze.customer     src_c ON src_c.customer_id = s.customer_id
JOIN TARGET.Customer_Dim  cust ON cust.customer_id  = s.customer_id
JOIN TARGET.Product_Dim   prod ON prod.product_id   = s.product_id
JOIN TARGET.Country_Dim   ctry ON ctry.country_code  = src_c.country_code;
 