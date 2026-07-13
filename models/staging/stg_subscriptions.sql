with source as (
    select * from {{ source('publishing_media', 'raw_subscriptions') }}
)

select
    subscription_id::number as subscription_id,
    {{ dbt_utils.generate_surrogate_key(['subscription_id']) }} as subscription_key,
    reader_id::number as reader_id,
    started_at::date as started_at,
    ended_at::date as ended_at,
    plan_name::varchar as plan_name,
    billing_period::varchar as billing_period,
    {{ pence_to_pounds('monthly_price_pence') }} as monthly_price_gbp,
    status::varchar as status
from source
