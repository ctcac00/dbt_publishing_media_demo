with reader_revenue as (
    select * from {{ ref('int_reader_revenue') }}
)

select
    reader_key,
    reader_id,
    email_domain,
    signup_date,
    acquisition_channel,
    country,
    age_band,
    marketing_opt_in,
    reader_status,
    subscription_count,
    active_subscription_count,
    monthly_recurring_revenue_gbp,
    first_subscription_date,
    last_subscription_activity_date,
    lifetime_pageviews,
    lifetime_engaged_seconds,
    last_seen_date,
    {{ safe_divide('lifetime_engaged_seconds', 'lifetime_pageviews') }} as avg_lifetime_engaged_seconds
from reader_revenue
