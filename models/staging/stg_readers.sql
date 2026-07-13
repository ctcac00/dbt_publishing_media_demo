with source as (
    select * from {{ source('publishing_media', 'raw_readers') }}
)

select
    reader_id::number as reader_id,
    {{ dbt_utils.generate_surrogate_key(['reader_id']) }} as reader_key,
    email_domain::varchar as email_domain,
    signup_date::date as signup_date,
    acquisition_channel::varchar as acquisition_channel,
    country::varchar as country,
    age_band::varchar as age_band,
    marketing_opt_in::boolean as marketing_opt_in
from source
