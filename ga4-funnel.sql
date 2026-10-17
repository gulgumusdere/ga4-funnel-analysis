-- GA4 E-Commerce Funnel Analysis
-- Data: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- Builds a session-level binary funnel (session start -> purchase),
-- then aggregates by date, device, traffic source and landing page
-- for the Tableau dashboard.

WITH base_events AS (
SELECT
  user_pseudo_id,

  -- SESSION ID
  CONCAT(
    user_pseudo_id,
    (SELECT value.int_value 
     FROM UNNEST(event_params) 
     WHERE key = 'ga_session_id')
  ) AS session_id,

--tarih timestampten
  DATE(TIMESTAMP_MICROS(event_timestamp)) AS event_date,
  event_name,

  -- Revenue
  (SELECT value.double_value 
   FROM UNNEST(event_params) 
   WHERE key = 'value') AS revenue,

  -- URL
  (SELECT value.string_value 
   FROM UNNEST(event_params) 
   WHERE key = 'page_location') AS page_location,

  -- CLEAN PAGE PATH (dashboard için)
  REGEXP_EXTRACT(
    (SELECT value.string_value 
      FROM UNNEST(event_params) 
      WHERE key = 'page_location'),
      r'https?://[^/]+(/.*)'
    ) AS page_path,

  -- Segmentler
  device.category AS device_category,
  device.language AS device_language,
  device.operating_system AS operating_system,
  traffic_source.source AS traffic_source,
  traffic_source.medium AS traffic_medium,
  traffic_source.name AS campaign

FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
)

, session_level AS (
SELECT
  session_id,

  MIN(event_date) AS session_date,

  -- Funnel step (var mı?)
 MAX(CASE WHEN event_name = 'session_start' THEN 1 ELSE 0 END) AS session_start,
    MAX(CASE WHEN event_name = 'view_item' THEN 1 ELSE 0 END) AS view_item,
    MAX(CASE WHEN event_name = 'add_to_cart' THEN 1 ELSE 0 END) AS add_to_cart,
    MAX(CASE WHEN event_name = 'begin_checkout' THEN 1 ELSE 0 END) AS begin_checkout,
    MAX(CASE WHEN event_name = 'add_shipping_info' THEN 1 ELSE 0 END) AS add_shipping_info,
    MAX(CASE WHEN event_name = 'add_payment_info' THEN 1 ELSE 0 END) AS add_payment_info,
    MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) AS purchase,

  -- Revenue
 SUM(CASE 
          WHEN event_name = 'purchase' THEN revenue 
          ELSE 0 
        END) AS total_revenue,

  -- Landing page (DOĞRU)
  MAX(CASE 
          WHEN event_name = 'session_start' 
          THEN REGEXP_EXTRACT(page_location, r'https?://[^/]+(/.*)')
          ELSE NULL 
        END) AS landing_page,

  -- Segmentler (tek değer almak için)
  ANY_VALUE(device_category) AS device_category,
  ANY_VALUE(device_language) AS device_language,
  ANY_VALUE(operating_system) AS operating_system,
  ANY_VALUE(traffic_source) AS traffic_source,
  ANY_VALUE(traffic_medium) AS traffic_medium,
  ANY_VALUE(campaign) AS campaign,

  ANY_VALUE(user_pseudo_id) AS user_pseudo_id


FROM base_events
GROUP BY session_id
)
SELECT

  session_date,
  device_category,
  device_language,
  operating_system,
  traffic_source,
  traffic_medium,
  campaign,
  landing_page,

-- Funnel metrics
  SUM(session_start) AS sessions,
  SUM(view_item) AS product_views,
  SUM(add_to_cart) AS add_to_cart,
  SUM(begin_checkout) AS begin_checkout,
  SUM(add_shipping_info) AS add_shipping_info,
  SUM(add_payment_info) AS add_payment_info,
  SUM(purchase) AS purchases,

-- Revenue
  SUM(total_revenue) AS total_revenue,

  --total_users
  COUNT(DISTINCT user_pseudo_id)AS total_users,

  -- KPI'lar
  SAFE_DIVIDE(SUM(purchase), COUNT(*)) * 100 AS session_conversion_rate,

  SAFE_DIVIDE(SUM(purchase),COUNT(DISTINCT user_pseudo_id))*100 AS user_conversion_rate,

  -- BONUS
  SAFE_DIVIDE(COUNT(*), COUNT(DISTINCT user_pseudo_id)) AS avg_sessions_per_user

FROM session_level

GROUP BY

  session_date,
  device_category,
  device_language,
  operating_system,
  traffic_source,
  traffic_medium,
  campaign,
  landing_page
;
