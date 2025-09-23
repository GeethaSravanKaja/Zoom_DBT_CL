sql
-- Bronze layer transformation for feature usage data
-- Performs 1:1 mapping from raw.feature_usage to bronze.bz_feature_usage with data validation

{{ config(
    materialized='table'
) }}

WITH source_data AS (
    -- Extract raw feature usage data with basic validation
    SELECT 
        usage_id,
        meeting_id,
        feature_name,
        usage_count,
        usage_date,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('raw', 'feature_usage') }}
    WHERE usage_id IS NOT NULL  -- Basic data quality check
),

validated_data AS (
    -- Apply data validation and cleansing rules
    SELECT 
        TRIM(usage_id) AS usage_id,
        TRIM(meeting_id) AS meeting_id,
        TRIM(feature_name) AS feature_name,
        CASE 
            WHEN usage_count < 0 THEN 0 
            ELSE usage_count 
        END AS usage_count,  -- Ensure non-negative usage count
        usage_date,
        load_timestamp,
        update_timestamp,
        COALESCE(source_system, '{{ var("source_system") }}') AS source_system
    FROM source_data
),

final_output AS (
    -- Final transformation with audit columns
    SELECT 
        usage_id,
        meeting_id,
        feature_name,
        usage_count,
        usage_date,
        CURRENT_TIMESTAMP() AS load_timestamp,
        CURRENT_TIMESTAMP() AS update_timestamp,
        source_system
    FROM validated_data
)

SELECT * FROM final_output
