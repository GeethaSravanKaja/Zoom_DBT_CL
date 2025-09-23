sql
-- Bronze layer transformation for support tickets data
-- Performs 1:1 mapping from raw.support_tickets to bronze.bz_support_tickets with data validation

{{ config(
    materialized='table'
) }}

WITH source_data AS (
    -- Extract raw support tickets data with basic validation
    SELECT 
        ticket_id,
        user_id,
        ticket_type,
        resolution_status,
        open_date,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('raw', 'support_tickets') }}
    WHERE ticket_id IS NOT NULL  -- Basic data quality check
),

validated_data AS (
    -- Apply data validation and cleansing rules
    SELECT 
        TRIM(ticket_id) AS ticket_id,
        TRIM(user_id) AS user_id,
        TRIM(ticket_type) AS ticket_type,
        UPPER(TRIM(resolution_status)) AS resolution_status,  -- Standardize status format
        open_date,
        load_timestamp,
        update_timestamp,
        COALESCE(source_system, '{{ var("source_system") }}') AS source_system
    FROM source_data
),

final_output AS (
    -- Final transformation with audit columns
    SELECT 
        ticket_id,
        user_id,
        ticket_type,
        resolution_status,
        open_date,
        CURRENT_TIMESTAMP() AS load_timestamp,
        CURRENT_TIMESTAMP() AS update_timestamp,
        source_system
    FROM validated_data
)

SELECT * FROM final_output
