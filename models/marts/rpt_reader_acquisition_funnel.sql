with readers as (
    select * from {{ ref('dim_readers') }}
),

paywall_events as (
    select * from {{ ref('stg_paywall_events') }}
),

paywall_reader_rollup as (
    select
        reader_id,
        count(*) as paywall_events,
        sum(case when event_type = 'paywall_view' then 1 else 0 end) as paywall_views,
        sum(case when conversion_status in ('converted', 'trial_started') then 1 else 0 end) as paywall_conversions,
        sum(revenue_gbp) as paywall_conversion_revenue_gbp
    from paywall_events
    group by 1
),

cohort_rollup as (
    select
        readers.signup_date as signup_cohort_date,
        readers.acquisition_channel,
        readers.country,
        readers.age_band,
        count(*) as registered_readers,
        sum(case when readers.marketing_opt_in then 1 else 0 end) as marketing_opt_in_readers,
        sum(case when readers.reader_status = 'subscriber' then 1 else 0 end) as subscriber_readers,
        sum(case when readers.reader_status = 'lapsed' then 1 else 0 end) as lapsed_readers,
        sum(readers.subscription_count) as subscriptions_started,
        sum(readers.active_subscription_count) as active_subscriptions,
        sum(readers.monthly_recurring_revenue_gbp) as monthly_recurring_revenue_gbp,
        coalesce(sum(paywall_reader_rollup.paywall_events), 0) as paywall_events,
        coalesce(sum(paywall_reader_rollup.paywall_views), 0) as paywall_views,
        coalesce(sum(paywall_reader_rollup.paywall_conversions), 0) as paywall_conversions,
        coalesce(sum(paywall_reader_rollup.paywall_conversion_revenue_gbp), 0) as paywall_conversion_revenue_gbp
    from readers
    left join paywall_reader_rollup
        on readers.reader_id = paywall_reader_rollup.reader_id
    group by 1, 2, 3, 4
)

select
    signup_cohort_date,
    acquisition_channel,
    country,
    age_band,
    registered_readers,
    marketing_opt_in_readers,
    subscriber_readers,
    lapsed_readers,
    subscriptions_started,
    active_subscriptions,
    monthly_recurring_revenue_gbp,
    paywall_events,
    paywall_views,
    paywall_conversions,
    paywall_conversion_revenue_gbp,
    {{ safe_divide('subscriber_readers', 'registered_readers') }} as subscriber_conversion_rate,
    {{ safe_divide('paywall_conversions', 'paywall_views') }} as paywall_conversion_rate
from cohort_rollup
