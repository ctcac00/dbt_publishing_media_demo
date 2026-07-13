# Publishing Media Demo

This dbt project models a generic digital publishing business on Snowflake. It answers questions about content engagement, reader revenue, and advertising yield by article section and acquisition channel.

## Data Model

- `seeds/` contains raw article, reader, pageview, subscription, and ad campaign data.
- `models/staging/` casts and renames seed fields into Snowflake-friendly staging refs.
- `models/intermediate/` builds article engagement and reader revenue rollups.
- `models/marts/` exposes `fct_article_performance` and `dim_readers` for analytics.

## Local Workflow

1. Confirm the `publishing_media_demo` profile exists in `~/.dbt/profiles.yml`.
2. Install packages with `dbt deps` when dependencies change.
3. Load seeds with `dbt seed`.
4. Build and test the graph with `dbt build`.

Terraform under `terraform/` creates dbt platform resources only: project, Snowflake connection, environments, credentials, and a daily Production `dbt build` job.
