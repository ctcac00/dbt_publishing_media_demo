with subscriptions as (
    select * from {{ ref('stg_subscriptions') }}
),

report_dates as (
    select started_at as report_date from subscriptions
    union
    select ended_at as report_date from subscriptions where ended_at is not null
),

subscription_daily as (
    select
        report_dates.report_date,
        subscriptions.plan_name,
        subscriptions.billing_period,
        subscriptions.status,
        sum(case when subscriptions.started_at = report_dates.report_date then 1 else 0 end) as subscription_starts,
        sum(case when subscriptions.ended_at = report_dates.report_date then 1 else 0 end) as subscription_cancellations,
        sum(
            case
                when subscriptions.started_at <= report_dates.report_date
                    and coalesce(subscriptions.ended_at, report_dates.report_date) >= report_dates.report_date
                    and subscriptions.status = 'active'
                    then 1
                else 0
            end
        ) as active_subscriptions,
        sum(
            case
                when subscriptions.started_at <= report_dates.report_date
                    and coalesce(subscriptions.ended_at, report_dates.report_date) >= report_dates.report_date
                    and subscriptions.status = 'trial'
                    then 1
                else 0
            end
        ) as trial_subscriptions,
        sum(
            case
                when subscriptions.started_at <= report_dates.report_date
                    and coalesce(subscriptions.ended_at, report_dates.report_date) >= report_dates.report_date
                    and subscriptions.status in ('active', 'trial')
                    then subscriptions.monthly_price_gbp
                else 0
            end
        ) as monthly_recurring_revenue_gbp
    from report_dates
    inner join subscriptions
        on subscriptions.started_at <= report_dates.report_date
        and coalesce(subscriptions.ended_at, report_dates.report_date) >= report_dates.report_date
    group by 1, 2, 3, 4
)

select
    report_date,
    plan_name,
    billing_period,
    status,
    subscription_starts,
    subscription_cancellations,
    active_subscriptions,
    trial_subscriptions,
    monthly_recurring_revenue_gbp,
    sum(monthly_recurring_revenue_gbp) over (
        partition by report_date
    ) as total_monthly_recurring_revenue_gbp
from subscription_daily
