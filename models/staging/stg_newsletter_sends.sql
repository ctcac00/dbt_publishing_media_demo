with source as (
    select * from {{ source('publishing_media', 'raw_newsletter_sends') }}
)

select
    send_id::number as send_id,
    {{ dbt_utils.generate_surrogate_key(['send_id']) }} as send_key,
    article_id::number as article_id,
    reader_id::number as reader_id,
    sent_at::timestamp_ntz as sent_at,
    newsletter_name::varchar as newsletter_name,
    send_status::varchar as send_status,
    opened_at::timestamp_ntz as opened_at,
    clicked_at::timestamp_ntz as clicked_at
from source
