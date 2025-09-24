{{ config(
 materialized='table',
 unique_key='device_dim_id'
) }}
WITH participant_devices AS (
 -- Extract device information from participants
 -- Note: Most device fields are not in Silver schema, so we'll create placeholders
 SELECT DISTINCT
 participant_id,
 user_id,
 load_date,
 update_date,
 source_system
 FROM {{ source('silver', 'sv_participants') }}
 WHERE participant_id IS NOT NULL
),
device_mapping AS (
 -- Create device mappings with available data
 SELECT 
 participant_id,
 user_id,
 load_date,
 update_date,
 source_system,
 -- Generate a device connection ID based on participant
 CONCAT('DEVICE_', participant_id) AS device_connection_id
 FROM participant_devices
),
final AS (
 -- Final transformation with device attributes
 SELECT 
 -- Surrogate key generation
 UUID_STRING() AS device_dim_id,
 
 -- Device connection identifier
 dm.device_connection_id,
 
 -- Device attributes (not available in Silver, set as NULL with proper data types)
 CAST(NULL AS VARCHAR(100)) AS device_type,
 CAST(NULL AS VARCHAR(100)) AS operating_system,
 CAST(NULL AS VARCHAR(50)) AS application_version,
 CAST(NULL AS VARCHAR(50)) AS network_connection_type,
 CAST(NULL AS VARCHAR(50)) AS device_category,
 CAST(NULL AS VARCHAR(50)) AS platform_family,
 
 -- Metadata columns
 dm.load_date,
 dm.update_date,
 dm.source_system,
 
 -- Audit columns
 CURRENT_TIMESTAMP() AS created_at,
 CURRENT_TIMESTAMP() AS updated_at,
 'PROCESSED' AS process_status
 
 FROM device_mapping dm
)
SELECT * FROM final