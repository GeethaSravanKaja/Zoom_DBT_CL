sql
-- Bronze layer transformation for meetings data
-- Performs 1:1 mapping from raw.meetings to bronze.bz_meetings with data validation

{{ config(
    materialized='table'
) }}

WITH source_data AS (
    -- Extract raw meetings data with basic validation
    SELECT 
        meeting_id,
        host_id,
        meeting_topic,
        start_time,
        end_time,
        duration_minutes,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('raw', 'meetings') }}
    WHERE meeting_id IS NOT NULL  -- Basic data quality check
),

validated_data AS (
    -- Apply data validation and cleansing rules
    SELECT 
        TRIM(meeting_id) AS meeting_id,
        TRIM(host_id) AS host_id,
        TRIM(meeting_topic) AS meeting_topic,
        start_time,
        end_time,
        CASE 
            WHEN duration_minutes < 0 THEN 0 
            ELSE duration_minutes 
        END AS duration_minutes,  -- Ensure non-negative duration
        load_timestamp,
        update_timestamp,
        COALESCE(source_system, '{{ var("source_system") }}') AS source_system
    FROM source_data
),

final_output AS (
    -- Final transformation with audit columns
    SELECT 
        meeting_id,
        host_id,
        meeting_topic,
        start_time,
        end_time,
        duration_minutes,
        CURRENT_TIMESTAMP() AS load_timestamp,
        CURRENT_TIMESTAMP() AS update_timestamp,
        source_system
    FROM validated_data
)

SELECT * FROM final_output
