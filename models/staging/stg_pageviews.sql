with source as (
    select * from {{ source('publishing_media', 'raw_pageviews') }}
)

select
    pageview_id::number as pageview_id,
    {{ dbt_utils.generate_surrogate_key(['pageview_id']) }} as pageview_key,
    article_id::number as article_id,
    reader_id::number as reader_id,
    viewed_at::timestamp_ntz as viewed_at,
    session_id::varchar as session_id,
    device_type::varchar as device_type,
    traffic_source::varchar as traffic_source,
    engaged_seconds::number as engaged_seconds,
    ad_impressions::number as ad_impressions
from source
