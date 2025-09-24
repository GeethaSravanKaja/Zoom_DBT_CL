{{ config(
 materialized='table',
 unique_key='time_dim_id'
) }}
WITH meeting_dates AS (
 -- Extract unique dates from meetings
 SELECT DISTINCT 
 CAST(start_time AS DATE) AS date_key,
 start_time,
 load_date,
 update_date,
 source_system
 FROM {{ source('silver', 'sv_meetings') }}
 WHERE start_time IS NOT NULL
),
webinar_dates AS (
 -- Extract unique dates from webinars
 SELECT DISTINCT 
 CAST(start_time AS DATE) AS date_key,
 start_time,
 load_date,
 update_date,
 source_system
 FROM {{ source('silver', 'sv_meetings') }}
 WHERE start_time IS NOT NULL
),
all_dates AS (
 -- Combine all dates
 SELECT date_key, start_time, load_date, update_date, source_system FROM meeting_dates
 UNION
 SELECT date_key, start_time, load_date, update_date, source_system FROM webinar_dates
),
date_attributes AS (
 -- Calculate date attributes
 SELECT DISTINCT
 date_key,
 start_time,
 load_date,
 update_date,
 source_system
 FROM all_dates
),
final AS (
 -- Final transformation with all time attributes
 SELECT 
 -- Surrogate key generation
 UUID_STRING() AS time_dim_id,
 
 -- Date key
 da.date_key,
 
 -- Year attributes
 EXTRACT(YEAR FROM da.date_key) AS year_number,
 EXTRACT(QUARTER FROM da.date_key) AS quarter_number,
 
 -- Month attributes
 EXTRACT(MONTH FROM da.date_key) AS month_number,
 TO_VARCHAR(da.date_key, 'MMMM') AS month_name,
 
 -- Week attributes
 EXTRACT(WEEK FROM da.date_key) AS week_number,
 
 -- Day attributes
 EXTRACT(DOY FROM da.date_key) AS day_of_year,
 EXTRACT(DAY FROM da.date_key) AS day_of_month,
 EXTRACT(DOW FROM da.date_key) AS day_of_week,
 TO_VARCHAR(da.date_key, 'DAY') AS day_name,
 
 -- Weekend indicator
 CASE 
 WHEN EXTRACT(DOW FROM da.date_key) IN (0,6) THEN TRUE 
 ELSE FALSE 
 END AS is_weekend,
 
 -- Holiday indicator (not available in Silver, set as FALSE)
 FALSE AS is_holiday,
 
 -- Fiscal year attributes (assuming calendar year = fiscal year)
 EXTRACT(YEAR FROM da.date_key) AS fiscal_year,
 EXTRACT(QUARTER FROM da.date_key) AS fiscal_quarter,
 
 -- Metadata columns
 da.load_date,
 da.update_date,
 da.source_system,
 
 -- Audit columns
 CURRENT_TIMESTAMP() AS created_at,
 CURRENT_TIMESTAMP() AS updated_at,
 'PROCESSED' AS process_status
 
 FROM date_attributes da
)
SELECT * FROM final
ORDER BY date_key