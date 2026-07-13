with source as (
    select * from {{ source('publishing_media', 'raw_ad_campaigns') }}
)

select
    campaign_id::number as campaign_id,
    {{ dbt_utils.generate_surrogate_key(['campaign_id']) }} as campaign_key,
    article_id::number as article_id,
    campaign_name::varchar as campaign_name,
    advertiser_category::varchar as advertiser_category,
    flight_start_date::date as flight_start_date,
    flight_end_date::date as flight_end_date,
    {{ pence_to_pounds('spend_pence') }} as spend_gbp,
    booked_impressions::number as booked_impressions
from source
