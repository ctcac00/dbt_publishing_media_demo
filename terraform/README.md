# Publishing Media Demo Terraform

This directory manages dbt platform resources only:

- dbt Cloud project
- Snowflake global connection
- Snowflake production credential using a sensitive keypair variable
- Development and Production environments
- Daily Production `dbt build` job

Provide `snowflake_private_key` through a secure Terraform variable mechanism. Do not commit private keys, service tokens, state files, or `*.tfvars` files containing secrets.
