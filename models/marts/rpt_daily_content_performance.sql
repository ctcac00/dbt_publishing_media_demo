with articles as (
    select * from {{ ref('stg_articles') }}
),

pageviews as (
    select * from {{ ref('stg_pageviews') }}
),

newsletter_sends as (
    select * from {{ ref('stg_newsletter_sends') }}
),

paywall_events as (
    select * from {{ ref('stg_paywall_events') }}
),

pageview_rollup as (
    select
        pageviews.viewed_at::date as report_date,
        articles.section,
        articles.primary_channel,
        articles.is_premium,
        count(*) as pageviews,
        count(distinct pageviews.reader_id) as unique_readers,
        count(distinct pageviews.session_id) as sessions,
        sum(pageviews.engaged_seconds) as engaged_seconds,
        sum(pageviews.ad_impressions) as delivered_ad_impressions
    from pageviews
    inner join articles
        on pageviews.article_id = articles.article_id
    group by 1, 2, 3, 4
),

newsletter_rollup as (
    select
        newsletter_sends.sent_at::date as report_date,
        articles.section,
        articles.primary_channel,
        articles.is_premium,
        count(*) as newsletter_sends,
        sum(case when newsletter_sends.send_status = 'sent' then 1 else 0 end) as delivered_newsletter_sends,
        sum(case when newsletter_sends.opened_at is not null then 1 else 0 end) as newsletter_opens,
        sum(case when newsletter_sends.clicked_at is not null then 1 else 0 end) as newsletter_clicks
    from newsletter_sends
    inner join articles
        on newsletter_sends.article_id = articles.article_id
    group by 1, 2, 3, 4
),

paywall_rollup as (
    select
        paywall_events.event_at::date as report_date,
        articles.section,
        articles.primary_channel,
        articles.is_premium,
        count(*) as paywall_events,
        sum(case when paywall_events.event_type = 'paywall_view' then 1 else 0 end) as paywall_views,
        sum(case when paywall_events.conversion_status in ('converted', 'trial_started') then 1 else 0 end) as paywall_conversions,
        sum(paywall_events.revenue_gbp) as paywall_conversion_revenue_gbp
    from paywall_events
    inner join articles
        on paywall_events.article_id = articles.article_id
    group by 1, 2, 3, 4
)

select
    coalesce(pageview_rollup.report_date, newsletter_rollup.report_date, paywall_rollup.report_date) as report_date,
    coalesce(pageview_rollup.section, newsletter_rollup.section, paywall_rollup.section) as section,
    coalesce(pageview_rollup.primary_channel, newsletter_rollup.primary_channel, paywall_rollup.primary_channel) as primary_channel,
    coalesce(pageview_rollup.is_premium, newsletter_rollup.is_premium, paywall_rollup.is_premium) as is_premium,
    coalesce(pageview_rollup.pageviews, 0) as pageviews,
    coalesce(pageview_rollup.unique_readers, 0) as unique_readers,
    coalesce(pageview_rollup.sessions, 0) as sessions,
    coalesce(pageview_rollup.engaged_seconds, 0) as engaged_seconds,
    coalesce(pageview_rollup.delivered_ad_impressions, 0) as delivered_ad_impressions,
    coalesce(newsletter_rollup.newsletter_sends, 0) as newsletter_sends,
    coalesce(newsletter_rollup.delivered_newsletter_sends, 0) as delivered_newsletter_sends,
    coalesce(newsletter_rollup.newsletter_opens, 0) as newsletter_opens,
    coalesce(newsletter_rollup.newsletter_clicks, 0) as newsletter_clicks,
    coalesce(paywall_rollup.paywall_events, 0) as paywall_events,
    coalesce(paywall_rollup.paywall_views, 0) as paywall_views,
    coalesce(paywall_rollup.paywall_conversions, 0) as paywall_conversions,
    coalesce(paywall_rollup.paywall_conversion_revenue_gbp, 0) as paywall_conversion_revenue_gbp,
    {{ safe_divide('pageview_rollup.engaged_seconds', 'pageview_rollup.pageviews') }} as avg_engaged_seconds,
    {{ safe_divide('newsletter_rollup.newsletter_opens', 'newsletter_rollup.delivered_newsletter_sends') }} as newsletter_open_rate,
    {{ safe_divide('newsletter_rollup.newsletter_clicks', 'newsletter_rollup.delivered_newsletter_sends') }} as newsletter_click_rate,
    {{ safe_divide('paywall_rollup.paywall_conversions', 'paywall_rollup.paywall_views') }} as paywall_conversion_rate
from pageview_rollup
full outer join newsletter_rollup
    on pageview_rollup.report_date = newsletter_rollup.report_date
    and pageview_rollup.section = newsletter_rollup.section
    and pageview_rollup.primary_channel = newsletter_rollup.primary_channel
    and pageview_rollup.is_premium = newsletter_rollup.is_premium
full outer join paywall_rollup
    on coalesce(pageview_rollup.report_date, newsletter_rollup.report_date) = paywall_rollup.report_date
    and coalesce(pageview_rollup.section, newsletter_rollup.section) = paywall_rollup.section
    and coalesce(pageview_rollup.primary_channel, newsletter_rollup.primary_channel) = paywall_rollup.primary_channel
    and coalesce(pageview_rollup.is_premium, newsletter_rollup.is_premium) = paywall_rollup.is_premium
