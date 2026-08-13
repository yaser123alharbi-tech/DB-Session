-- =====================================================================
-- Stored Procedures: Load data using MERGE from STG (staging) tables into TARGET Dimension and Fact tables
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. Load COUNTRY_DIM
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE TARGET.merge_country_dim()
LANGUAGE plpgsql
AS $$
BEGIN
    MERGE INTO TARGET.Country_Dim AS tgt
    USING STG.country AS src
    ON tgt.country_code = src.country_code          -- how we match rows

    WHEN MATCHED THEN                                 -- row already exists -> update it
        UPDATE SET
            country_name = src.country_name,
            region       = src.region

    WHEN NOT MATCHED THEN                              -- row doesn't exist yet -> insert it
        INSERT (country_code, country_name, region)
        VALUES (src.country_code, src.country_name, src.region);

    COMMIT;
END;
$$;


-- ---------------------------------------------------------------------
-- 2. Load CUSTOMER_DIM
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE TARGET.merge_customer_dim()
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
END;
$$;


-- ---------------------------------------------------------------------
-- 3. Load PRODUCT_DIM
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE TARGET.merge_product_dim()
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
END;
$$;


-- ---------------------------------------------------------------------
-- 4. Load SALES_TRANSACTION_FACT
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE TARGET.merge_sales_transaction_fact()
LANGUAGE plpgsql
AS $$
BEGIN
    MERGE INTO TARGET.Sales_Transactions_Fact AS tgt
    USING (
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
END;
$$;


-- =====================================================================
-- How to run them (order matters: Dims first, then the Fact table)
-- =====================================================================
CALL TARGET.merge_country_dim();
CALL TARGET.merge_customer_dim();
CALL TARGET.merge_product_dim();
CALL TARGET.merge_sales_transaction_fact();