# Team PR Requests

This folder is the intake area for other teams to submit Kafka topic/ACL changes through pull requests.

## Folder structure

Each PR should add one request folder using this pattern:

`team-pr-requests/<team-name>/<request-id>/request.tfvars`

Example:

`team-pr-requests/payments/CHG0033439/request.tfvars`

## How teams submit a request

1. Copy `team-pr-requests/_template/request.tfvars.example`.
2. Create your folder using `<team-name>/<request-id>`.
3. Save the file as `request.tfvars`.
4. Open a PR with your request file.

## Mandatory fields by current use-case

- Topic creation: `environment`, topic `name`
- Producer ACL: `topic_name` (`cn` optional; CN-only values are expanded)
- Consumer ACL: `group_id`, `topic_name` (`cn` optional; CN-only values are expanded)

When `cn` is omitted, `default_principal_cn` is used (`core-sc-allocations-processor`).

## Validation rules applied by Terraform module

- Environment must be one of `DEV`, `QA`, `PREPROD`, `PROD`
- Every ACL `topic_name` must exist in the same `topics` list
- DLT topic defaults apply (`partitions=1`, `replication_factor=1`) unless overridden

## Running a team request

Run from `tf-kafka` root:

```powershell
Set-Location "C:\Users\Allen.Catadman\IdeaProjects\editor\tf-kafka"
terraform init
terraform validate
terraform plan -var-file="team-pr-requests/payments/CHG0033439/request.tfvars"
```

For apply:

```powershell
Set-Location "C:\Users\Allen.Catadman\IdeaProjects\editor\tf-kafka"
terraform apply -var-file="team-pr-requests/payments/CHG0033439/request.tfvars"
```
