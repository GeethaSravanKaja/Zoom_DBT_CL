sql
-- Bronze layer transformation for webinars data
-- Performs 1:1 mapping from raw.webinars to bronze.bz_webinars with data validation

{{ config(
    materialized='table'
) }}

WITH source_data AS (
    -- Extract raw webinars data with basic validation
    SELECT 
        webinar_id,
        host_id,
        webinar_topic,
        start_time,
        end_time,
        registrants,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('raw', 'webinars') }}
    WHERE webinar_id IS NOT NULL  -- Basic data quality check
),

validated_data AS (
    -- Apply data validation and cleansing rules
    SELECT 
        TRIM(webinar_id) AS webinar_id,
        TRIM(host_id) AS host_id,
        TRIM(webinar_topic) AS webinar_topic,
        start_time,
        end_time,
        CASE 
            WHEN registrants < 0 THEN 0 
            ELSE registrants 
        END AS registrants,  -- Ensure non-negative registrant count
        load_timestamp,
        update_timestamp,
        COALESCE(source_system, '{{ var("source_system") }}') AS source_system
    FROM source_data
),

final_output AS (
    -- Final transformation with audit columns
    SELECT 
        webinar_id,
        host_id,
        webinar_topic,
        start_time,
        end_time,
        registrants,
        CURRENT_TIMESTAMP() AS load_timestamp,
        CURRENT_TIMESTAMP() AS update_timestamp,
        source_system
    FROM validated_data
)

SELECT * FROM final_output
