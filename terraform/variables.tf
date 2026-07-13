variable "dbt_account_id" {
  description = "dbt Cloud account ID."
  type        = number
}

variable "dbt_service_token" {
  description = "dbt Cloud service token with permissions to manage projects, environments, credentials, and jobs."
  type        = string
  sensitive   = true
}

variable "dbt_access_url" {
  description = "dbt Cloud access URL, such as https://cloud.getdbt.com."
  type        = string
  default     = "https://cloud.getdbt.com"
}

variable "snowflake_account" {
  description = "Snowflake account identifier."
  type        = string
  default     = "zna84829"
}

variable "snowflake_user" {
  description = "Snowflake user for dbt Cloud deployment credentials."
  type        = string
  default     = "CARLOS_CASTRO"
}

variable "snowflake_database" {
  description = "Snowflake database."
  type        = string
  default     = "ccastro_sandbox"
}

variable "snowflake_warehouse" {
  description = "Snowflake warehouse."
  type        = string
  default     = "transforming"
}

variable "snowflake_role" {
  description = "Snowflake role."
  type        = string
  default     = "TRANSFORMER"
}

variable "snowflake_threads" {
  description = "dbt execution thread count for Snowflake."
  type        = number
  default     = 6
}

variable "snowflake_dev_schema" {
  description = "Development schema used by local and personal dbt Cloud credentials."
  type        = string
  default     = "publishing_media_demo_ccastro"
}

variable "snowflake_prod_schema" {
  description = "Production deployment schema."
  type        = string
  default     = "publishing_media_demo_prod"
}

variable "snowflake_private_key_path" {
  description = "Path to the Snowflake private key for the dbt Cloud production credential."
  type        = string
  sensitive   = true
}

variable "snowflake_private_key_version" {
  description = "Increment when rotating the Snowflake private key write-only value."
  type        = number
  default     = 1
}
