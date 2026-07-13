# Publishing Media Demo

This dbt project models a generic digital publishing business on Snowflake. It answers questions about content engagement, reader revenue, and advertising yield by article section and acquisition channel.

## Data Model

- `seeds/` contains raw article, reader, pageview, subscription, ad campaign, newsletter send, and paywall event data.
- `models/staging/` casts and renames seed fields into Snowflake-friendly staging refs.
- `models/intermediate/` builds article engagement and reader revenue rollups.
- `models/marts/` exposes `fct_article_performance` and `dim_readers` for analytics.

## Local Workflow

1. Confirm the `publishing_media_demo` profile exists in `~/.dbt/profiles.yml`.
2. Install packages with `dbt deps` when dependencies change.
3. Optionally regenerate larger demo seed files with `python scripts/generate_seed_data.py --rows-per-source 1000`.
4. Load seeds with `dbt seed`.
5. Build and test the graph with `dbt build`.

The seed generator is deterministic and idempotent. It preserves the small hand-authored rows in `seeds/`, replaces rows in its generated ID ranges, and writes about 1,000 synthetic rows per raw source by default. Use `--dry-run` to preview row counts without changing the CSV files.

Terraform under `terraform/` creates dbt platform resources only: project, Snowflake connection, environments, credentials, and a daily Production `dbt build` job.
