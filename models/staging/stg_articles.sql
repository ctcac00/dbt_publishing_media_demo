with source as (
    select * from {{ source('publishing_media', 'raw_articles') }}
)

select
    article_id::number as article_id,
    {{ dbt_utils.generate_surrogate_key(['article_id']) }} as article_key,
    headline::varchar as headline,
    section::varchar as section,
    author::varchar as author,
    published_at::timestamp_ntz as published_at,
    primary_channel::varchar as primary_channel,
    word_count::number as word_count,
    is_premium::boolean as is_premium
from source
