sql
-- Bronze layer transformation for licenses data
-- Performs 1:1 mapping from raw.licenses to bronze.bz_licenses with data validation

{{ config(
    materialized='table'
) }}

WITH source_data AS (
    -- Extract raw licenses data with basic validation
    SELECT 
        license_id,
        license_type,
        assigned_to_user_id,
        start_date,
        end_date,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('raw', 'licenses') }}
    WHERE license_id IS NOT NULL  -- Basic data quality check
),

validated_data AS (
    -- Apply data validation and cleansing rules
    SELECT 
        TRIM(license_id) AS license_id,
        UPPER(TRIM(license_type)) AS license_type,  -- Standardize license type format
        TRIM(assigned_to_user_id) AS assigned_to_user_id,
        start_date,
        end_date,
        load_timestamp,
        update_timestamp,
        COALESCE(source_system, '{{ var("source_system") }}') AS source_system
    FROM source_data
),

final_output AS (
    -- Final transformation with audit columns
    SELECT 
        license_id,
        license_type,
        assigned_to_user_id,
        start_date,
        end_date,
        CURRENT_TIMESTAMP() AS load_timestamp,
        CURRENT_TIMESTAMP() AS update_timestamp,
        source_system
    FROM validated_data
)

SELECT * FROM final_output
