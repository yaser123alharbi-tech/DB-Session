
-- ---------------------------------------------------------------------
-- 0. Error log table
-- Every failed procedure writes one row here.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS TARGET.Error_Log (
    Log_Id           SERIAL PRIMARY KEY,
    Procedure_Name   VARCHAR(100),
    Error_Code       VARCHAR(20),     -- Postgres equivalent of SQLCODE is SQLSTATE
    Error_Message    VARCHAR(2000),   -- Postgres equivalent of SQLERRM is SQLERRM
    Logged_At        TIMESTAMP DEFAULT clock_timestamp()
);


-- ---------------------------------------------------------------------
-- 1. LOG_ERROR procedure (parameterized)
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE TARGET.log_error(
    p_procedure_name  VARCHAR,
    p_error_code      VARCHAR,
    p_error_message   VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO TARGET.Error_Log (Procedure_Name, Error_Code, Error_Message)
    VALUES (p_procedure_name, p_error_code, p_error_message);

    COMMIT;
END;
$$;


-- =====================================================================
-- PACKAGE 1 (schema): PKG_FULL_LOAD
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS PKG_FULL_LOAD;

CREATE OR REPLACE PROCEDURE PKG_FULL_LOAD.load_country_dim()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE TARGET.Country_Dim;

    INSERT INTO TARGET.Country_Dim (country_code, country_name, region)
    SELECT country_code, country_name, region
    FROM STG.country;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        CALL TARGET.log_error('PKG_FULL_LOAD.load_country_dim', SQLSTATE, SQLERRM);
END;
$$;


CREATE OR REPLACE PROCEDURE PKG_FULL_LOAD.load_customer_dim()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE TARGET.Customer_Dim;

    INSERT INTO TARGET.Customer_Dim (customer_id, customer_name, country_code, customer_type)
    SELECT customer_id, customer_name, country_code, customer_type
    FROM STG.customer;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        CALL TARGET.log_error('PKG_FULL_LOAD.load_customer_dim', SQLSTATE, SQLERRM);
END;
$$;


CREATE OR REPLACE PROCEDURE PKG_FULL_LOAD.load_product_dim()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE TARGET.Product_Dim;

    INSERT INTO TARGET.Product_Dim (product_id, product_name, category, standard_price)
    SELECT product_id, product_name, category, standard_price
    FROM STG.product;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        CALL TARGET.log_error('PKG_FULL_LOAD.load_product_dim', SQLSTATE, SQLERRM);
END;
$$;


CREATE OR REPLACE PROCEDURE PKG_FULL_LOAD.load_sales_transaction_fact()
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
        s.transaction_id, s.transaction_date, s.customer_id, s.product_id,
        s.quantity, s.unit_price, s.total_amount, s.payment_mode,
        crd.Country_Key, cud.Customer_Key, prd.Product_Key
    FROM STG.sales_transactions s
    JOIN STG.customer          sc  ON sc.customer_id   = s.customer_id
    JOIN TARGET.Customer_Dim   cud ON cud.customer_id  = s.customer_id
    JOIN TARGET.Product_Dim    prd ON prd.product_id   = s.product_id
    JOIN TARGET.Country_Dim    crd ON crd.country_code = sc.country_code;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        CALL TARGET.log_error('PKG_FULL_LOAD.load_sales_transaction_fact', SQLSTATE, SQLERRM);
END;
$$;


-- =====================================================================
-- PACKAGE 2 (schema): PKG_INCREMENTAL_LOAD
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS PKG_INCREMENTAL_LOAD;

CREATE OR REPLACE PROCEDURE PKG_INCREMENTAL_LOAD.merge_country_dim()
LANGUAGE plpgsql
AS $$
BEGIN
    MERGE INTO TARGET.Country_Dim AS tgt
    USING STG.country AS src
    ON tgt.country_code = src.country_code
    WHEN MATCHED THEN
        UPDATE SET country_name = src.country_name, region = src.region
    WHEN NOT MATCHED THEN
        INSERT (country_code, country_name, region)
        VALUES (src.country_code, src.country_name, src.region);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        CALL TARGET.log_error('PKG_INCREMENTAL_LOAD.merge_country_dim', SQLSTATE, SQLERRM);
END;
$$;


CREATE OR REPLACE PROCEDURE PKG_INCREMENTAL_LOAD.merge_customer_dim()
LANGUAGE plpgsql
AS $$
BEGIN
    MERGE INTO TARGET.Customer_Dim AS tgt
    USING STG.customer AS src
    ON tgt.customer_id = src.customer_id
    WHEN MATCHED THEN
        UPDATE SET
            customer_name = src.customer_name,
            country_code  = src.country_code,
            customer_type = src.customer_type
    WHEN NOT MATCHED THEN
        INSERT (customer_id, customer_name, country_code, customer_type)
        VALUES (src.customer_id, src.customer_name, src.country_code, src.customer_type);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        CALL TARGET.log_error('PKG_INCREMENTAL_LOAD.merge_customer_dim', SQLSTATE, SQLERRM);
END;
$$;


CREATE OR REPLACE PROCEDURE PKG_INCREMENTAL_LOAD.merge_product_dim()
LANGUAGE plpgsql
AS $$
BEGIN
    MERGE INTO TARGET.Product_Dim AS tgt
    USING STG.product AS src
    ON tgt.product_id = src.product_id
    WHEN MATCHED THEN
        UPDATE SET
            product_name   = src.product_name,
            category       = src.category,
            standard_price = src.standard_price
    WHEN NOT MATCHED THEN
        INSERT (product_id, product_name, category, standard_price)
        VALUES (src.product_id, src.product_name, src.category, src.standard_price);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        CALL TARGET.log_error('PKG_INCREMENTAL_LOAD.merge_product_dim', SQLSTATE, SQLERRM);
END;
$$;


CREATE OR REPLACE PROCEDURE PKG_INCREMENTAL_LOAD.merge_sales_transaction_fact()
LANGUAGE plpgsql
AS $$
BEGIN
    MERGE INTO TARGET.Sales_Transactions_Fact AS tgt
    USING (
        SELECT
            s.transaction_id, s.transaction_date, s.customer_id, s.product_id,
            s.quantity, s.unit_price, s.total_amount, s.payment_mode,
            crd.Country_Key, cud.Customer_Key, prd.Product_Key
        FROM STG.sales_transactions s
        JOIN STG.customer          sc  ON sc.customer_id   = s.customer_id
        JOIN TARGET.Customer_Dim   cud ON cud.customer_id  = s.customer_id
        JOIN TARGET.Product_Dim    prd ON prd.product_id   = s.product_id
        JOIN TARGET.Country_Dim    crd ON crd.country_code = sc.country_code
    ) AS src
    ON tgt.transaction_id = src.transaction_id
    WHEN MATCHED THEN
        UPDATE SET
            transaction_date = src.transaction_date,
            customer_id      = src.customer_id,
            product_id       = src.product_id,
            quantity         = src.quantity,
            unit_price       = src.unit_price,
            total_amount     = src.total_amount,
            payment_mode     = src.payment_mode,
            Country_Key      = src.Country_Key,
            Customer_Key     = src.Customer_Key,
            Product_Key      = src.Product_Key
    WHEN NOT MATCHED THEN
        INSERT (
            transaction_id, transaction_date, customer_id, product_id,
            quantity, unit_price, total_amount, payment_mode,
            Country_Key, Customer_Key, Product_Key
        )
        VALUES (
            src.transaction_id, src.transaction_date, src.customer_id, src.product_id,
            src.quantity, src.unit_price, src.total_amount, src.payment_mode,
            src.Country_Key, src.Customer_Key, src.Product_Key
        );

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        CALL TARGET.log_error('PKG_INCREMENTAL_LOAD.merge_sales_transaction_fact', SQLSTATE, SQLERRM);
END;
$$;



-- =====================================================================
-- How to run them
-- =====================================================================

CALL PKG_FULL_LOAD.load_country_dim();
CALL PKG_FULL_LOAD.load_customer_dim();
CALL PKG_FULL_LOAD.load_product_dim();
CALL PKG_FULL_LOAD.load_sales_transaction_fact();

-- Incremental load (dims first, then fact):
CALL PKG_INCREMENTAL_LOAD.merge_country_dim();
CALL PKG_INCREMENTAL_LOAD.merge_customer_dim();
CALL PKG_INCREMENTAL_LOAD.merge_product_dim();
CALL PKG_INCREMENTAL_LOAD.merge_sales_transaction_fact();

-- Check the error log any time:
SELECT * FROM TARGET.Error_Log ORDER BY Logged_At DESC;