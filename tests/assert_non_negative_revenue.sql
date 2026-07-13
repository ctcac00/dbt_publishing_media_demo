select article_id
from {{ ref('fct_article_performance') }}
where booked_ad_revenue_gbp < 0
