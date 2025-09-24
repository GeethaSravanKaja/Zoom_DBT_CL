{{ config(
 materialized='table',
 unique_key='user_dim_id'
) }}
WITH user_base AS (
 -- Base user information from Silver layer
 SELECT 
 user_id,
 user_name,
 email,
 company,
 plan_type,
 record_status,
 load_date,
 update_date,
 source_system,
 load_timestamp,
 update_timestamp
 FROM {{ source('silver', 'sv_users') }}
 WHERE record_status = 'ACTIVE'
),
latest_licenses AS (
 -- Get the latest license for each user
 SELECT 
 assigned_to_user_id,
 license_type,
 ROW_NUMBER() OVER (PARTITION BY assigned_to_user_id ORDER BY start_date DESC) as rn
 FROM {{ source('silver', 'sv_licenses') }}
 WHERE assigned_to_user_id IS NOT NULL
),
user_licenses AS (
 -- Filter to get only the latest license per user
 SELECT 
 assigned_to_user_id,
 license_type
 FROM latest_licenses
 WHERE rn = 1
),
final AS (
 -- Final transformation with all business rules applied
 SELECT 
 -- Surrogate key generation
 UUID_STRING() AS user_dim_id,
 
 -- Business key
 ub.user_id,
 
 -- User attributes with transformations
 ub.user_name,
 ub.email AS email_address,
 
 -- Map plan_type to user_type
 CASE 
 WHEN ub.plan_type = 'Pro' THEN 'Professional'
 WHEN ub.plan_type = 'Basic' THEN 'Basic'
 WHEN ub.plan_type = 'Enterprise' THEN 'Enterprise'
 ELSE COALESCE(ub.plan_type, 'Unknown')
 END AS user_type,
 
 -- Map record_status to account_status
 CASE 
 WHEN ub.record_status = 'ACTIVE' THEN 'Active'
 WHEN ub.record_status = 'INACTIVE' THEN 'Inactive'
 WHEN ub.record_status = 'SUSPENDED' THEN 'Suspended'
 ELSE COALESCE(ub.record_status, 'Unknown')
 END AS account_status,
 
 -- License information from joined table
 COALESCE(ul.license_type, 'No License') AS license_type,
 
 -- Fields not available in Silver - set as NULL with proper data types
 CAST(NULL AS VARCHAR(200)) AS department_name,
 CAST(NULL AS VARCHAR(200)) AS job_title,
 CAST(NULL AS VARCHAR(50)) AS time_zone,
 CAST(NULL AS DATE) AS account_creation_date,
 CAST(NULL AS DATE) AS last_login_date,
 CAST(NULL AS VARCHAR(50)) AS language_preference,
 CAST(NULL AS VARCHAR(50)) AS phone_number,
 
 -- Metadata columns
 ub.load_date,
 ub.update_date,
 ub.source_system,
 
 -- Audit columns
 CURRENT_TIMESTAMP() AS created_at,
 CURRENT_TIMESTAMP() AS updated_at,
 'PROCESSED' AS process_status
 
 FROM user_base ub
 LEFT JOIN user_licenses ul ON ub.user_id = ul.assigned_to_user_id
)
SELECT * FROM final