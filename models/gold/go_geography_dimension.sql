{{ config(
 materialized='table',
 unique_key='geography_dim_id'
) }}
WITH default_geography AS (
 -- Create default geography records since no geography data in Silver
 SELECT 
 'US' AS country_code,
 'United States' AS country_name,
 'North America' AS region_name,
 'America/New_York' AS time_zone,
 'North America' AS continent,
 CURRENT_DATE() AS load_date,
 CURRENT_DATE() AS update_date,
 'DEFAULT' AS source_system
 
 UNION ALL
 
 SELECT 
 'CA' AS country_code,
 'Canada' AS country_name,
 'North America' AS region_name,
 'America/Toronto' AS time_zone,
 'North America' AS continent,
 CURRENT_DATE() AS load_date,
 CURRENT_DATE() AS update_date,
 'DEFAULT' AS source_system
 
 UNION ALL
 
 SELECT 
 'UK' AS country_code,
 'United Kingdom' AS country_name,
 'Europe' AS region_name,
 'Europe/London' AS time_zone,
 'Europe' AS continent,
 CURRENT_DATE() AS load_date,
 CURRENT_DATE() AS update_date,
 'DEFAULT' AS source_system
),
final AS (
 -- Final transformation with geography attributes
 SELECT 
 -- Surrogate key generation
 UUID_STRING() AS geography_dim_id,
 
 -- Geography attributes
 dg.country_code,
 dg.country_name,
 dg.region_name,
 dg.time_zone,
 dg.continent,
 
 -- Metadata columns
 dg.load_date,
 dg.update_date,
 dg.source_system,
 
 -- Audit columns
 CURRENT_TIMESTAMP() AS created_at,
 CURRENT_TIMESTAMP() AS updated_at,
 'PROCESSED' AS process_status
 
 FROM default_geography dg
)
SELECT * FROM final