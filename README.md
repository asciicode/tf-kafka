# tf-kafka

Terraform templates for Kafka topic + ACL creation with environment defaults based on `../kafka.md`.

## What this covers

- Topic creation (`kafka_topic`)
- Producer ACL creation (topic write/describe + cluster idempotent write)
- Consumer ACL creation (topic read/describe + group read)
- Strict validation that ACL `topic_name` values exist in your `topics` list
- Environment defaults for `DEV`, `QA`, `PREPROD`, `PROD`
- DLT topic default rule (`partitions=1`, `replication_factor=1` when topic contains `DLT`)

## Mandatory fields (current use-case)

- Topic creation: `environment`, topic `name`
- Producer ACL: `topic_name` (`cn` optional)
- Consumer ACL: `topic_name` (`cn` optional, `group_id` optional)

## Files

- `versions.tf` provider and Terraform version constraints
- `variables.tf` inputs + validation
- `locals.tf` environment mapping + defaults + DLT logic
- `provider.tf` Kafka provider bootstrap configuration
- `main.tf` topic + ACL resources
- `outputs.tf` resolved values for visibility
- `terraform.tfvars.example` sample input
- `team-pr-requests/` PR intake folder for other teams

## Quick start

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and update values.
2. Run Terraform commands below.

```powershell
Set-Location "C:\Users\Allen.Catadman\IdeaProjects\editor\tf-kafka"
terraform init
terraform plan
terraform apply
```

## Docker Terraform commands

If you run Terraform via Docker (service `terraform`), use these commands:

```powershell
Set-Location "C:\Users\Allen.Catadman\IdeaProjects\editor\tf-kafka"
docker compose run --rm -T --entrypoint terraform terraform init
docker compose run --rm -T --entrypoint terraform terraform validate
docker compose run --rm -T --entrypoint terraform terraform plan -var-file="local-docker.tfvars" -var='bootstrap_server_override=host.docker.internal:9092'
docker compose run --rm -T --entrypoint terraform terraform apply -var-file="local-docker.tfvars" -var='bootstrap_server_override=host.docker.internal:9092'
```

Use `host.docker.internal:9092` when Terraform runs inside Docker and Kafka is reachable from the host.

## Notes

- `command_config_path` is kept as a mapped output for parity with your Kafka CLI workflow.
- `cn` can be either `CN` only, full DN (`CN=...,OU=...`), or full principal (`User:CN=...`).
- For CN-only values, this module expands to `User:CN=<cn>,OU=IT,O=Foodstuffs North Island,L=<env>,ST=Auckland,C=NZ`.
- If `cn` is omitted, the module uses `default_principal_cn = "core-sc-allocations-processor"`.
- Environment principal location mapping is automatic: `DEV -> L=DEV`, `QA/PREPROD -> L=TEST`, `PROD -> L=PROD`.
- For consumer topic ACLs, `topic_operations` can be set per entry (default: `Read`, `Describe`).
- Group ACL is created only when `group_id` is provided.

## Provider auth inputs (optional)

- TLS:
  - `kafka_tls_enabled` (default `true`)
  - `kafka_skip_tls_verify` (default `false`)
  - `kafka_ca_cert` (optional cert content)
- mTLS:
  - `kafka_client_cert` (optional cert content)
  - `kafka_client_key` (optional key content)
- SASL:
  - `kafka_sasl_username` (optional)
  - `kafka_sasl_password` (optional, sensitive)
  - `kafka_sasl_mechanism` (optional: `plain`, `scram-sha256`, `scram-sha512`)

If these are not set, Terraform uses broker-only config from environment defaults.

## Local Kafka endpoint notes

- If Terraform runs on your host machine, use `bootstrap_server_override = "localhost:9092"`.
- If Terraform runs inside the `terraform` Docker container, use `bootstrap_server_override = "host.docker.internal:9092"`.

## GitHub Actions CI/CD

Workflows are in `.github/workflows/`:

| Workflow | Trigger | Action |
|---|---|---|
| `terraform-plan.yml` | PR opened/updated | Posts `terraform plan` output as PR comment |
| `terraform-apply.yml` | Merge to `main` | Runs `terraform apply -auto-approve` |

### Required GitHub Secrets

Set these in your repo **Settings → Secrets → Actions**:

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | AWS key for S3 state backend |
| `AWS_SECRET_ACCESS_KEY` | AWS secret for S3 state backend |
| `AWS_REGION` | AWS region (e.g. `ap-southeast-2`) |
| `KAFKA_BOOTSTRAP_SERVER` | Kafka broker endpoint per environment |

### Remote state (required for CI)

Update `backend.tf` with your S3 bucket name and DynamoDB lock table.

---

## Team PR intake flow

Other teams should submit PRs under `team-pr-requests/` using:

- `team-pr-requests/<team-name>/<request-id>/request.tfvars`

Use `team-pr-requests/_template/request.tfvars.example` as the starting template.

Run a request:

```powershell
Set-Location "C:\Users\Allen.Catadman\IdeaProjects\editor\tf-kafka"
terraform init
terraform validate
terraform plan -var-file="team-pr-requests/payments/CHG0033439/request.tfvars"
```

```