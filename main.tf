check "producer_acl_topics_exist" {
  assert {
    condition     = length(local.unknown_producer_topics) == 0
    error_message = "Producer ACL topic_name values must exist in topics list. Unknown topics: ${join(", ", tolist(local.unknown_producer_topics))}"
  }
}

check "consumer_acl_topics_exist" {
  assert {
    condition     = length(local.unknown_consumer_topics) == 0
    error_message = "Consumer ACL topic_name values must exist in topics list. Unknown topics: ${join(", ", tolist(local.unknown_consumer_topics))}"
  }
}

resource "kafka_topic" "this" {
  for_each = local.resolved_topics

  name               = each.value.name
  partitions         = each.value.partitions
  replication_factor = each.value.replication_factor

  config = {
    "cleanup.policy"      = each.value.cleanup_policy
    "retention.ms"        = tostring(each.value.retention_ms)
    "min.insync.replicas" = tostring(each.value.min_insync_replicas)
  }
}

resource "kafka_acl" "producer_topic" {
  for_each = local.producer_topic_acls

  resource_name       = each.value.topic
  resource_type       = "Topic"
  acl_principal       = each.value.principal
  acl_host            = "*"
  acl_operation       = each.value.operation
  acl_permission_type = "Allow"
}

resource "kafka_acl" "producer_cluster_idempotent" {
  for_each = local.producer_cluster_idempotent_acls

  resource_name       = "kafka-cluster"
  resource_type       = "Cluster"
  acl_principal       = each.value
  acl_host            = "*"
  acl_operation       = "IdempotentWrite"
  acl_permission_type = "Allow"
}

resource "kafka_acl" "consumer_topic" {
  for_each = local.consumer_topic_acls

  resource_name       = each.value.topic
  resource_type       = "Topic"
  acl_principal       = each.value.principal
  acl_host            = "*"
  acl_operation       = each.value.operation
  acl_permission_type = "Allow"
}

resource "kafka_acl" "consumer_group" {
  for_each = local.consumer_group_acls

  resource_name       = each.value.group_id
  resource_type       = "Group"
  acl_principal       = each.value.principal
  acl_host            = "*"
  acl_operation       = "Read"
  acl_permission_type = "Allow"
}
