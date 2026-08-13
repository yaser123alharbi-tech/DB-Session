-- =====================================================================
-- Stored Procedures: Load data from STG tables into the TARGET Dimension and Fact tables
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. Load COUNTRY_DIM
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE TARGET.load_country_dim()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Step 1: empty the table
    TRUNCATE TABLE TARGET.Country_Dim;

    -- Step 2: copy data from staging into the target table
    INSERT INTO TARGET.Country_Dim (country_code, country_name, region)
    SELECT country_code, country_name, region
    FROM STG.country;

    -- Step 3: save the changes
    COMMIT;
END;
$$;


-- ---------------------------------------------------------------------
-- 2. Load CUSTOMER_DIM
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE TARGET.load_customer_dim()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE TARGET.Customer_Dim;

    INSERT INTO TARGET.Customer_Dim (customer_id, customer_name, country_code, customer_type)
    SELECT customer_id, customer_name, country_code, customer_type
    FROM STG.customer;

    COMMIT;
END;
$$;


-- ---------------------------------------------------------------------
-- 3. Load PRODUCT_DIM
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE TARGET.load_product_dim()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE TARGET.Product_Dim;

    INSERT INTO TARGET.Product_Dim (product_id, product_name, category, standard_price)
    SELECT product_id, product_name, category, standard_price
    FROM STG.product;

    COMMIT;
END;
$$;


-- ---------------------------------------------------------------------
-- 4. Load SALES_TRANSACTION_FACT
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE TARGET.load_sales_transaction_fact()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE TARGET.Sales_Transactions_Fact;

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
        crd.Country_Key,
        cud.Customer_Key,
        prd.Product_Key
    FROM STG.sales_transactions s
    JOIN STG.customer          sc  ON sc.customer_id  = s.customer_id
    JOIN TARGET.Customer_Dim   cud ON cud.customer_id = s.customer_id
    JOIN TARGET.Product_Dim    prd ON prd.product_id  = s.product_id
    JOIN TARGET.Country_Dim    crd ON crd.country_code = sc.country_code;

    COMMIT;
END;
$$;


-- =====================================================================
-- How to run them (order matters: Dims first, then the Fact table)
-- =====================================================================
CALL TARGET.load_country_dim();
CALL TARGET.load_customer_dim();
CALL TARGET.load_product_dim();
CALL TARGET.load_sales_transaction_fact();