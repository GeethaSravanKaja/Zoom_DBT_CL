sql
-- Bronze layer transformation for billing events data
-- Performs 1:1 mapping from raw.billing_events to bronze.bz_billing_events with data validation

{{ config(
    materialized='table'
) }}

WITH source_data AS (
    -- Extract raw billing events data with basic validation
    SELECT 
        event_id,
        user_id,
        event_type,
        amount,
        event_date,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('raw', 'billing_events') }}
    WHERE event_id IS NOT NULL  -- Basic data quality check
),

validated_data AS (
    -- Apply data validation and cleansing rules
    SELECT 
        TRIM(event_id) AS event_id,
        TRIM(user_id) AS user_id,
        UPPER(TRIM(event_type)) AS event_type,  -- Standardize event type format
        CASE 
            WHEN amount < 0 THEN 0.00 
            ELSE amount 
        END AS amount,  -- Ensure non-negative amounts
        event_date,
        load_timestamp,
        update_timestamp,
        COALESCE(source_system, '{{ var("source_system") }}') AS source_system
    FROM source_data
),

final_output AS (
    -- Final transformation with audit columns
    SELECT 
        event_id,
        user_id,
        event_type,
        amount,
        event_date,
        CURRENT_TIMESTAMP() AS load_timestamp,
        CURRENT_TIMESTAMP() AS update_timestamp,
        source_system
    FROM validated_data
)

SELECT * FROM final_output
