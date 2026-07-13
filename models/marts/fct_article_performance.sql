{{ config(
    materialized='incremental',
    unique_key='article_key',
    on_schema_change='sync_all_columns'
) }}

with articles as (
    select * from {{ ref('stg_articles') }}
),

article_engagement as (
    select * from {{ ref('int_article_engagement') }}
)

select
    articles.article_key,
    articles.article_id,
    articles.headline,
    articles.section,
    articles.author,
    articles.published_at,
    articles.primary_channel,
    articles.word_count,
    articles.is_premium,
    coalesce(article_engagement.pageviews, 0) as pageviews,
    coalesce(article_engagement.unique_readers, 0) as unique_readers,
    coalesce(article_engagement.sessions, 0) as sessions,
    coalesce(article_engagement.engaged_seconds, 0) as engaged_seconds,
    coalesce(article_engagement.delivered_ad_impressions, 0) as delivered_ad_impressions,
    article_engagement.first_viewed_date,
    article_engagement.last_viewed_date,
    coalesce(article_engagement.campaign_count, 0) as campaign_count,
    coalesce(article_engagement.booked_ad_revenue_gbp, 0) as booked_ad_revenue_gbp,
    coalesce(article_engagement.booked_impressions, 0) as booked_impressions,
    article_engagement.avg_engaged_seconds,
    article_engagement.booked_cpm_gbp,
    current_timestamp as updated_at
from articles
left join article_engagement
    on articles.article_id = article_engagement.article_id
{% if is_incremental() %}
where articles.published_at >= (
    select coalesce(dateadd(day, -7, max(published_at)), '1900-01-01'::timestamp_ntz)
    from {{ this }}
)
{% endif %}
