## Kafka Topic / ACL Request

**Team:** <!-- e.g. payments, supply-chain, wholesale -->
**Change ID:** <!-- e.g. CHG0033439 -->
**Environment:** <!-- DEV / QA / PREPROD / PROD -->

---

### Request file

`team-pr-requests/<team>/<change-id>/request.tfvars`

---

### Checklist

- [ ] Copied template from `team-pr-requests/_template/request.tfvars.example`
- [ ] `environment` is set correctly (`DEV`, `QA`, `PREPROD`, `PROD`)
- [ ] All `topic_name` values in `producers`/`consumers` exist in `topics` list
- [ ] CN values are correct (CN-only, full DN, or full `User:CN=...`)
- [ ] DLT topics use `partitions=1`, `replication_factor=1` (or overridden intentionally)
- [ ] Terraform Plan output has been reviewed (auto-posted as PR comment)
- [ ] No sensitive values (certs, passwords) are committed in the request file

---

### Topics to create

| Name | Partitions | Replication | Retention (ms) |
|------|-----------|-------------|----------------|
|      |           |             |                |

### Producers

| CN | Topic |
|----|-------|
|    |       |

### Consumers

| CN | Group ID | Topic |
|----|---------|-------|
|    |         |       |
