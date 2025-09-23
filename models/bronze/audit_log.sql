sql
-- Audit log table for tracking bronze layer processing
-- This model creates the audit log table used by all other bronze models

{{ config(
    materialized='table',
    pre_hook=none,
    post_hook=none
) }}

WITH audit_structure AS (
    SELECT
        CAST(NULL AS STRING) AS table_name,
        CAST(NULL AS TIMESTAMP_NTZ) AS process_start_time,
        CAST(NULL AS TIMESTAMP_NTZ) AS process_end_time,
        CAST(NULL AS STRING) AS process_status,
        CAST(NULL AS TIMESTAMP_NTZ) AS created_at,
        CAST(NULL AS TIMESTAMP_NTZ) AS updated_at
    WHERE 1=0  -- This ensures no rows are returned, just structure
)

SELECT 
    table_name,
    process_start_time,
    process_end_time,
    process_status,
    created_at,
    updated_at
FROM audit_structure
