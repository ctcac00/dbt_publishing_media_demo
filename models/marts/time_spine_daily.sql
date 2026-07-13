with days as (

    {{
        dbt_utils.date_spine(
            datepart = "day",
            start_date = "to_date('2020-01-01')",
            end_date = "to_date('2031-01-01')"
        )
    }}

),

final as (

    select cast(date_day as date) as date_day
    from days

)

select *
from final
