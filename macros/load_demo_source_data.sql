{% macro load_demo_source_data(demo_case='engagement', demo_batch_id=none) %}
    {% set batch_id = demo_batch_id if demo_batch_id is not none else invocation_id %}
    {% set batch_id_sql = batch_id | replace("'", "''") %}

    {% if demo_case != 'engagement' %}
        {{ exceptions.raise_compiler_error("Unsupported demo_case '" ~ demo_case ~ "'. Supported values: engagement.") }}
    {% endif %}

    {% set merge_sql %}
        merge into {{ source('publishing_media', 'raw_pageviews') }} as target
        using (
            with demo_rows as (
                select
                    '{{ batch_id_sql }}' as demo_batch_id,
                    1 as row_number,
                    1005 as article_id,
                    2008 as reader_id,
                    dateadd(minute, -4, current_timestamp())::timestamp_ntz as viewed_at,
                    'desktop' as device_type,
                    'newsletter' as traffic_source,
                    185 as engaged_seconds,
                    6 as ad_impressions
                union all
                select
                    '{{ batch_id_sql }}' as demo_batch_id,
                    2 as row_number,
                    1003 as article_id,
                    2001 as reader_id,
                    dateadd(minute, -2, current_timestamp())::timestamp_ntz as viewed_at,
                    'mobile' as device_type,
                    'newsletter' as traffic_source,
                    142 as engaged_seconds,
                    5 as ad_impressions
                union all
                select
                    '{{ batch_id_sql }}' as demo_batch_id,
                    3 as row_number,
                    1001 as article_id,
                    2002 as reader_id,
                    current_timestamp()::timestamp_ntz as viewed_at,
                    'mobile' as device_type,
                    'search' as traffic_source,
                    96 as engaged_seconds,
                    4 as ad_impressions
            )

            select
                900000000000 + abs(mod(hash(demo_batch_id), 100000000)) * 10 + row_number as pageview_id,
                article_id,
                reader_id,
                viewed_at,
                'demo_' || abs(hash(demo_batch_id))::varchar || '_' || row_number::varchar as session_id,
                device_type,
                traffic_source,
                engaged_seconds,
                ad_impressions
            from demo_rows
        ) as source
            on target.pageview_id = source.pageview_id
        when matched then update set
            target.article_id = source.article_id,
            target.reader_id = source.reader_id,
            target.viewed_at = source.viewed_at,
            target.session_id = source.session_id,
            target.device_type = source.device_type,
            target.traffic_source = source.traffic_source,
            target.engaged_seconds = source.engaged_seconds,
            target.ad_impressions = source.ad_impressions
        when not matched then insert (
            pageview_id,
            article_id,
            reader_id,
            viewed_at,
            session_id,
            device_type,
            traffic_source,
            engaged_seconds,
            ad_impressions
        ) values (
            source.pageview_id,
            source.article_id,
            source.reader_id,
            source.viewed_at,
            source.session_id,
            source.device_type,
            source.traffic_source,
            source.engaged_seconds,
            source.ad_impressions
        )
    {% endset %}

    {% do run_query(merge_sql) %}
    {% do log("Loaded demo source data for demo_case='" ~ demo_case ~ "' and demo_batch_id='" ~ batch_id ~ "'.", info=true) %}
{% endmacro %}
