{{ config(
 materialized='table',
 unique_key='organization_dim_id'
) }}
WITH user_companies AS (
 -- Extract unique companies from users table
 SELECT DISTINCT
 company,
 load_date,
 update_date,
 source_system
 FROM {{ source('silver', 'sv_users') }}
 WHERE company IS NOT NULL
),
organization_mapping AS (
 -- Create organization mappings
 SELECT 
 company,
 load_date,
 update_date,
 source_system,
 -- Generate organization ID from company name
 CONCAT('ORG_', UPPER(REPLACE(company, ' ', '_'))) AS organization_id
 FROM user_companies
),
final AS (
 -- Final transformation with organization attributes
 SELECT 
 -- Surrogate key generation
 UUID_STRING() AS organization_dim_id,
 
 -- Business key
 om.organization_id,
 
 -- Organization name from company
 om.company AS organization_name,
 
 -- Organization attributes (not available in Silver, set as NULL with proper data types)
 CAST(NULL AS VARCHAR(200)) AS industry_classification,
 CAST(NULL AS VARCHAR(50)) AS organization_size,
 CAST(NULL AS VARCHAR(320)) AS primary_contact_email,
 CAST(NULL AS VARCHAR(1000)) AS billing_address,
 CAST(NULL AS VARCHAR(255)) AS account_manager_name,
 CAST(NULL AS DATE) AS contract_start_date,
 CAST(NULL AS DATE) AS contract_end_date,
 CAST(NULL AS NUMBER) AS maximum_user_limit,
 CAST(NULL AS NUMBER) AS storage_quota_gb,
 CAST(NULL AS VARCHAR(100)) AS security_policy_level,
 
 -- Metadata columns
 om.load_date,
 om.update_date,
 om.source_system,
 
 -- Audit columns
 CURRENT_TIMESTAMP() AS created_at,
 CURRENT_TIMESTAMP() AS updated_at,
 'PROCESSED' AS process_status
 
 FROM organization_mapping om
)
SELECT * FROM final