with pageviews as (
    select * from {{ ref('stg_pageviews') }}
),

ad_campaigns as (
    select * from {{ ref('stg_ad_campaigns') }}
),

pageview_rollup as (
    select
        article_id,
        count(*) as pageviews,
        count(distinct reader_id) as unique_readers,
        count(distinct session_id) as sessions,
        sum(engaged_seconds) as engaged_seconds,
        sum(ad_impressions) as delivered_ad_impressions,
        min(viewed_at)::date as first_viewed_date,
        max(viewed_at)::date as last_viewed_date
    from pageviews
    group by 1
),

campaign_rollup as (
    select
        article_id,
        count(*) as campaign_count,
        sum(spend_gbp) as booked_ad_revenue_gbp,
        sum(booked_impressions) as booked_impressions
    from ad_campaigns
    group by 1
)

select
    pageview_rollup.article_id,
    pageview_rollup.pageviews,
    pageview_rollup.unique_readers,
    pageview_rollup.sessions,
    pageview_rollup.engaged_seconds,
    pageview_rollup.delivered_ad_impressions,
    pageview_rollup.first_viewed_date,
    pageview_rollup.last_viewed_date,
    coalesce(campaign_rollup.campaign_count, 0) as campaign_count,
    coalesce(campaign_rollup.booked_ad_revenue_gbp, 0) as booked_ad_revenue_gbp,
    coalesce(campaign_rollup.booked_impressions, 0) as booked_impressions,
    {{ safe_divide('pageview_rollup.engaged_seconds', 'pageview_rollup.pageviews') }} as avg_engaged_seconds,
    {{ safe_divide('campaign_rollup.booked_ad_revenue_gbp * 1000', 'campaign_rollup.booked_impressions') }} as booked_cpm_gbp
from pageview_rollup
left join campaign_rollup
    on pageview_rollup.article_id = campaign_rollup.article_id
