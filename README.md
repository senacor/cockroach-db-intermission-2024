# cockroach-db-intermission-2024
infrastructure setup for CockroachDB on multiple cloud providers

# Prerequisites
- terraform >=1.8.2
- ansible >= 2.9.6
- jq https://jqlang.github.io/jq/

# AWS
## Create a cluster in one region
- adapt the parameters in the `infrastructure/aws/main.tf`
- run `aws_create_cluster_one_region $PATH_TO_PRIVATE_KEY_FILE`[setup](setup)