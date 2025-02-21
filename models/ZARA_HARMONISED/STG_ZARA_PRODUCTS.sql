{{ config(schema='ZARA_HARMONISED') }}
select * from {{source ('SCHEMA_1', 'ZARA_PRODUCTS')}}
 
