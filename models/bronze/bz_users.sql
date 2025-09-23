sql
-- Bronze layer transformation for users data
-- Performs 1:1 mapping from raw.users to bronze.bz_users with data validation and audit columns

{{ config(
    materialized='table'
) }}

WITH source_data AS (
    -- Extract raw users data with basic validation
    SELECT 
        user_id,
        user_name,
        email,
        company,
        plan_type,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('raw', 'users') }}
    WHERE user_id IS NOT NULL  -- Basic data quality check
),

validated_data AS (
    -- Apply data validation and cleansing rules
    SELECT 
        TRIM(user_id) AS user_id,
        TRIM(user_name) AS user_name,
        LOWER(TRIM(email)) AS email,  -- Standardize email format
        TRIM(company) AS company,
        UPPER(TRIM(plan_type)) AS plan_type,  -- Standardize plan type format
        load_timestamp,
        update_timestamp,
        COALESCE(source_system, '{{ var("source_system") }}') AS source_system
    FROM source_data
),

final_output AS (
    -- Final transformation with audit columns
    SELECT 
        user_id,
        user_name,
        email,
        company,
        plan_type,
        CURRENT_TIMESTAMP() AS load_timestamp,
        CURRENT_TIMESTAMP() AS update_timestamp,
        source_system
    FROM validated_data
)

SELECT * FROM final_output
