with source as (
    select * from {{ source('publishing_media', 'raw_paywall_events') }}
)

select
    paywall_event_id::number as paywall_event_id,
    {{ dbt_utils.generate_surrogate_key(['paywall_event_id']) }} as paywall_event_key,
    article_id::number as article_id,
    reader_id::number as reader_id,
    event_at::timestamp_ntz as event_at,
    event_type::varchar as event_type,
    offer_name::varchar as offer_name,
    conversion_status::varchar as conversion_status,
    {{ pence_to_pounds('revenue_pence') }} as revenue_gbp
from source
