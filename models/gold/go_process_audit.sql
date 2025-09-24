{{ config(
 materialized='table',
 unique_key='execution_id'
) }}
-- This model creates the audit table structure
-- The actual audit records are inserted via pre/post hooks
SELECT 
 CAST(NULL AS VARCHAR(50)) AS execution_id,
 CAST(NULL AS VARCHAR(200)) AS pipeline_name,
 CAST(NULL AS VARCHAR(100)) AS process_type,
 CAST(NULL AS TIMESTAMP_NTZ) AS start_time,
 CAST(NULL AS TIMESTAMP_NTZ) AS end_time,
 CAST(NULL AS VARCHAR(50)) AS status,
 CAST(NULL AS VARCHAR(2000)) AS error_message,
 CAST(NULL AS NUMBER) AS records_processed,
 CAST(NULL AS NUMBER) AS records_successful,
 CAST(NULL AS NUMBER) AS records_failed,
 CAST(NULL AS NUMBER) AS processing_duration_seconds,
 CAST(NULL AS VARCHAR(100)) AS source_system,
 CAST(NULL AS VARCHAR(100)) AS target_system,
 CAST(NULL AS VARCHAR(100)) AS user_executed,
 CAST(NULL AS VARCHAR(100)) AS server_name,
 CAST(NULL AS NUMBER) AS memory_usage_mb,
 CAST(NULL AS NUMBER(5,2)) AS cpu_usage_percent,
 CAST(NULL AS NUMBER(10,2)) AS data_volume_gb,
 CAST(NULL AS DATE) AS load_date,
 CAST(NULL AS DATE) AS update_date
WHERE 1=0 -- This ensures no records are selected initially
