{{
  config(
    materialized = "table",   
  )
}}
SELECT DISTINCT 
    product_id,
    name ,
    sku ,
    brand ,
    clothing_category ,
    section ,
    terms ,
    promotion ,
    seasonal 
FROM {{source ('DIM_PR', 'ZARA_INTERMEDIATE')}}