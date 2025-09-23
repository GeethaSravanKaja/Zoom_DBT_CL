sql
-- Bronze layer transformation for participants data
-- Performs 1:1 mapping from raw.participants to bronze.bz_participants with data validation

{{ config(
    materialized='table'
) }}

WITH source_data AS (
    -- Extract raw participants data with basic validation
    SELECT 
        participant_id,
        meeting_id,
        user_id,
        join_time,
        leave_time,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('raw', 'participants') }}
    WHERE participant_id IS NOT NULL  -- Basic data quality check
),

validated_data AS (
    -- Apply data validation and cleansing rules
    SELECT 
        TRIM(participant_id) AS participant_id,
        TRIM(meeting_id) AS meeting_id,
        TRIM(user_id) AS user_id,
        join_time,
        leave_time,
        load_timestamp,
        update_timestamp,
        COALESCE(source_system, '{{ var("source_system") }}') AS source_system
    FROM source_data
),

final_output AS (
    -- Final transformation with audit columns
    SELECT 
        participant_id,
        meeting_id,
        user_id,
        join_time,
        leave_time,
        CURRENT_TIMESTAMP() AS load_timestamp,
        CURRENT_TIMESTAMP() AS update_timestamp,
        source_system
    FROM validated_data
)

SELECT * FROM final_output
