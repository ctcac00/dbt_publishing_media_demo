with readers as (
    select * from {{ ref('stg_readers') }}
),

subscriptions as (
    select * from {{ ref('stg_subscriptions') }}
),

pageviews as (
    select * from {{ ref('stg_pageviews') }}
),

subscription_rollup as (
    select
        reader_id,
        count(*) as subscription_count,
        sum(case when status = 'active' then 1 else 0 end) as active_subscription_count,
        sum(monthly_price_gbp) as monthly_recurring_revenue_gbp,
        min(started_at) as first_subscription_date,
        max(coalesce(ended_at, current_date)) as last_subscription_activity_date
    from subscriptions
    group by 1
),

engagement_rollup as (
    select
        reader_id,
        count(*) as lifetime_pageviews,
        sum(engaged_seconds) as lifetime_engaged_seconds,
        max(viewed_at)::date as last_seen_date
    from pageviews
    group by 1
)

select
    readers.reader_id,
    readers.reader_key,
    readers.email_domain,
    readers.signup_date,
    readers.acquisition_channel,
    readers.country,
    readers.age_band,
    readers.marketing_opt_in,
    coalesce(subscription_rollup.subscription_count, 0) as subscription_count,
    coalesce(subscription_rollup.active_subscription_count, 0) as active_subscription_count,
    coalesce(subscription_rollup.monthly_recurring_revenue_gbp, 0) as monthly_recurring_revenue_gbp,
    subscription_rollup.first_subscription_date,
    subscription_rollup.last_subscription_activity_date,
    coalesce(engagement_rollup.lifetime_pageviews, 0) as lifetime_pageviews,
    coalesce(engagement_rollup.lifetime_engaged_seconds, 0) as lifetime_engaged_seconds,
    engagement_rollup.last_seen_date,
    case
        when coalesce(subscription_rollup.active_subscription_count, 0) > 0 then 'subscriber'
        when coalesce(subscription_rollup.subscription_count, 0) > 0 then 'lapsed'
        else 'registered'
    end as reader_status
from readers
left join subscription_rollup
    on readers.reader_id = subscription_rollup.reader_id
left join engagement_rollup
    on readers.reader_id = engagement_rollup.reader_id
