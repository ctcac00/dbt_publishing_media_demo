with ad_campaigns as (
    select * from {{ ref('stg_ad_campaigns') }}
),

articles as (
    select * from {{ ref('stg_articles') }}
),

pageviews as (
    select * from {{ ref('stg_pageviews') }}
),

delivery_rollup as (
    select
        ad_campaigns.campaign_id,
        count(distinct pageviews.pageview_id) as campaign_pageviews,
        coalesce(sum(pageviews.ad_impressions), 0) as delivered_impressions
    from ad_campaigns
    left join pageviews
        on ad_campaigns.article_id = pageviews.article_id
        and pageviews.viewed_at::date between ad_campaigns.flight_start_date and ad_campaigns.flight_end_date
    group by 1
)

select
    ad_campaigns.campaign_key,
    ad_campaigns.campaign_id,
    ad_campaigns.campaign_name,
    ad_campaigns.advertiser_category,
    ad_campaigns.article_id,
    articles.article_key,
    articles.section,
    articles.primary_channel,
    ad_campaigns.flight_start_date,
    ad_campaigns.flight_end_date,
    ad_campaigns.spend_gbp as booked_spend_gbp,
    ad_campaigns.booked_impressions,
    delivery_rollup.campaign_pageviews,
    delivery_rollup.delivered_impressions,
    {{ safe_divide('delivery_rollup.delivered_impressions', 'ad_campaigns.booked_impressions') }} as delivery_rate,
    {{ safe_divide('ad_campaigns.spend_gbp * 1000', 'ad_campaigns.booked_impressions') }} as booked_cpm_gbp,
    {{ safe_divide('ad_campaigns.spend_gbp * 1000', 'delivery_rollup.delivered_impressions') }} as delivered_cpm_gbp
from ad_campaigns
inner join articles
    on ad_campaigns.article_id = articles.article_id
left join delivery_rollup
    on ad_campaigns.campaign_id = delivery_rollup.campaign_id
