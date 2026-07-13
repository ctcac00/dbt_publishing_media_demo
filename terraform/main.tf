terraform {
  required_version = ">= 1.11.0"

  required_providers {
    dbtcloud = {
      source  = "dbt-labs/dbtcloud"
      version = ">= 1.0.0"
    }
  }
}

provider "dbtcloud" {
  account_id = var.dbt_account_id
  token      = var.dbt_service_token
  host_url   = var.dbt_access_url
}

resource "dbtcloud_project" "publishing_media_demo" {
  name = "publishing_media_demo"
}

resource "dbtcloud_global_connection" "snowflake" {
  name = "publishing_media_demo_snowflake"

  snowflake = {
    account                   = var.snowflake_account
    database                  = var.snowflake_database
    warehouse                 = var.snowflake_warehouse
    client_session_keep_alive = false
  }
}

resource "dbtcloud_snowflake_credential" "production" {
  project_id             = dbtcloud_project.publishing_media_demo.id
  auth_type              = "keypair"
  num_threads            = var.snowflake_threads
  schema                 = var.snowflake_prod_schema
  user                   = var.snowflake_user
  database               = var.snowflake_database
  warehouse              = var.snowflake_warehouse
  role                   = var.snowflake_role
  private_key_wo         = var.snowflake_private_key
  private_key_wo_version = var.snowflake_private_key_version
}

resource "dbtcloud_environment" "development" {
  dbt_version   = "latest"
  name          = "Development"
  project_id    = dbtcloud_project.publishing_media_demo.id
  type          = "development"
  connection_id = dbtcloud_global_connection.snowflake.id
}

resource "dbtcloud_environment" "production" {
  dbt_version     = "latest"
  name            = "Production"
  project_id      = dbtcloud_project.publishing_media_demo.id
  type            = "deployment"
  deployment_type = "production"
  connection_id   = dbtcloud_global_connection.snowflake.id
  credential_id   = dbtcloud_snowflake_credential.production.credential_id
}

resource "dbtcloud_job" "daily_production_build" {
  environment_id       = dbtcloud_environment.production.environment_id
  execute_steps        = ["dbt build"]
  generate_docs        = true
  is_active            = true
  name                 = "Daily Production build"
  num_threads          = var.snowflake_threads
  project_id           = dbtcloud_project.publishing_media_demo.id
  run_generate_sources = true
  target_name          = "prod"

  triggers = {
    github_webhook       = false
    git_provider_webhook = false
    schedule             = true
    on_merge             = false
  }

  schedule_days  = [0, 1, 2, 3, 4, 5, 6]
  schedule_type  = "days_of_week"
  schedule_hours = [6]

  execution = {
    timeout_seconds = 3600
  }
}
