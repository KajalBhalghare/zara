{{ config(materialized="incremental", incremental_strategy="append") }}
select distinct
    ctid_fivetran_id,
    product_id,
    product_position,
    promotion,
    seasonal,
    sales_volume,
    brand,
    url,
    sku,
    name,
    description,
    price as price_usd,
    price * 83 as price_inr,

    terms,
    section,
    case
        when sales_volume < 1000
        then 30
        when sales_volume between 1000 and 1500
        then 20
        else 15
    end as discount,
    sales_volume * price * (1 - discount / 100) as revenue,
    case
        when
            lower(description) like '%cropped%'
            or lower(description) like '%short length%'
            or lower(description) like '%above waist%'
            or lower(description) like '%crop top%'
        then 'Cropped'

        when
            lower(description) like '%regular fit%'
            or lower(description) like '%standard length%'
            or lower(description) like '%hip-length%'
            or lower(description) like '%classic fit%'
        then 'Regular'

        when
            lower(description) like '%longline%'
            or lower(description) like '%extended length%'
            or lower(description) like '%below hip%'
            or lower(description) like '%tunic%'
            or lower(description) like '%long fit%'
        then 'Longline'

        else 'Unknown'
    end as hemline_category,
    case
        when
            lower(name) like '%jacket%'
            or lower(description) like '%jacket%'
            or lower(name) like '%coat%'
            or lower(description) like '%coat%'
            or lower(name) like '%wool%'
            or lower(description) like '%wool%'
            or lower(name) like '%thermal%'
            or lower(description) like '%thermal%'
            or lower(name) like '%sweater%'
            or lower(description) like '%sweater%'
            or lower(name) like '%fleece%'
            or lower(description) like '%fleece%'
            or lower(name) like '%puffer%'
            or lower(description) like '%puffer%'
        then 'Winter'

        when
            lower(name) like '%shorts%'
            or lower(description) like '%shorts%'
            or lower(name) like '%t-shirt%'
            or lower(description) like '%t-shirt%'
            or lower(name) like '%linen%'
            or lower(description) like '%linen%'
            or lower(name) like '%cotton%'
            or lower(description) like '%cotton%'
            or lower(name) like '%sandals%'
            or lower(description) like '%sandals%'
            or lower(name) like '%sleeveless%'
            or lower(description) like '%sleeveless%'
            or lower(name) like '%swimwear%'
            or lower(description) like '%swimwear%'
        then 'Summer'

        when
            lower(name) like '%raincoat%'
            or lower(description) like '%raincoat%'
            or lower(name) like '%waterproof%'
            or lower(description) like '%waterproof%'
            or lower(name) like '%boots%'
            or lower(description) like '%boots%'
            or lower(name) like '%umbrella%'
            or lower(description) like '%umbrella%'
            or lower(name) like '%hooded%'
            or lower(description) like '%hooded%'
            or lower(name) like '%trench%'
            or lower(description) like '%trench%'
        then 'Rainy'

        else 'All-Season'
    end as season_category,
    case
        -- Winter Wear Category
        when
            lower(name) like '%puffer%'
            or lower(name) like '%wool%'
            or lower(name) like '%coat%'
            or lower(name) like '%sweater%'
            or lower(name) like '%winter%'
            or lower(name) like '%cold%'
        then 'Winter Wear'

        -- Leather Category
        when lower(name) like '%leather%' or lower(name) like '%faux leather%'
        then 'Leather'

        -- Denim Category
        when lower(name) like '%denim%' or lower(name) like '%jean%'
        then 'Denim'

        -- Casuals Category
        when
            lower(name) like '%t-shirt%'
            or lower(name) like '%polo%'
            or lower(name) like '%hoodie%'
            or lower(name) like '%sweatshirt%'
            or lower(name) like '%jogger%'
            or lower(name) like '%casual%'
        then 'Casuals'

        -- Formals Category
        when
            lower(name) like '%suit%'
            or lower(name) like '%blazer%'
            or lower(name) like '%formal%'
            or lower(name) like '%trousers%'
            or lower(name) like '%tuxedo%'
        then 'Formals'

        -- Jackets Category (excluding those already in Winter Wear or Leather)
        when
            lower(name) like '%jacket%'
            and lower(name) not like '%puffer%'
            and lower(name) not like '%leather%'
        then 'Jackets'

        -- Overshirts Category
        when lower(name) like '%overshirt%'
        then 'Overshirts'

        -- Bomber Jackets Category
        when lower(name) like '%bomber%'
        then 'Bomber Jackets'

        -- Sneakers Category
        when lower(name) like '%sneakers%' or lower(name) like '%shoes%'
        then 'Sneakers'

        -- Plaid Items Category
        when lower(name) like '%plaid%'
        then 'Plaid Items'

        -- Suede Items Category (similar to Leather but separately categorized)
        when lower(name) like '%suede%'
        then 'Suede Items'

        -- Faux Items Category
        when lower(name) like '%faux%'
        then 'Faux Items'

        else 'Others'
    end as clothing_category,

    scraped_at,
    _fivetran_deleted,
    _fivetran_synced
from {{ source("SCHEMA_1", "ZARA_PRODUCTS") }}
{% if is_incremental() %}

    -- this filter will only be applied on an incremental run
    -- (uses >= to include records whose timestamp occurred since the last run of this
    -- model)
    -- (If event_time is NULL or the table is truncated, the condition will always be
    -- true and load all records)
    where
        _fivetran_synced
        >= (select coalesce(max(_fivetran_synced), '2025-02-10') from {{ this }})

{% endif %}
