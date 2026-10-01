locals {
	environment = upper(var.environment)

	env_defaults = {
		DEV = {
			bootstrap_server    = "b-3.dev-msk-cluster.a0zd0g.c3.kafka.ap-southeast-2.amazonaws.com:9094"
			command_config_path = "client-dev.properties"
			principal_location  = "DEV"
			default_suffix      = "-dev"
			topic_defaults = {
				partitions         = 3
				replication_factor = 3
				retention_ms       = 604800000
			}
		}
		QA = {
			bootstrap_server    = "b-3.test-msk-cluster.g0rw43.c3.kafka.ap-southeast-2.amazonaws.com:9094"
			command_config_path = "c:/tmp/client-qa.properties"
			principal_location  = "TEST"
			default_suffix      = "-qa"
			topic_defaults = {
				partitions         = 3
				replication_factor = 3
				retention_ms       = 604800000
			}
		}
		PREPROD = {
			bootstrap_server    = "b-3.test-msk-cluster.g0rw43.c3.kafka.ap-southeast-2.amazonaws.com:9094"
			command_config_path = "c:/tmp/client-qa.properties"
			principal_location  = "TEST"
			default_suffix      = "-preprod"
			topic_defaults = {
				partitions         = 3
				replication_factor = 3
				retention_ms       = 604800000
			}
		}
		PROD = {
			bootstrap_server    = "b-3.prod-msk-cluster.ct0fhe.c4.kafka.ap-southeast-2.amazonaws.com:9094"
			command_config_path = "c:/tmp/client-prod.properties"
			principal_location  = "PROD"
			default_suffix      = ""
			topic_defaults = {
				partitions         = 6
				replication_factor = 3
				retention_ms       = 1209600000
			}
		}
	}

	selected_env          = local.env_defaults[local.environment]
	bootstrap_server      = coalesce(var.bootstrap_server_override, local.selected_env.bootstrap_server)
	command_config_path   = coalesce(var.command_config_path_override, local.selected_env.command_config_path)
	principal_dn_suffix   = "OU=${var.principal_ou},O=${var.principal_org},L=${local.selected_env.principal_location},ST=${var.principal_state},C=${var.principal_country}"

	resolved_topics = {
		for t in var.topics : t.name => {
			name       = t.name
			partitions = coalesce(
				try(t.partitions, null),
				length(regexall("(?i)dlt", t.name)) > 0 ? 1 : local.selected_env.topic_defaults.partitions
			)
			replication_factor = coalesce(
				try(t.replication_factor, null),
				length(regexall("(?i)dlt", t.name)) > 0 ? 1 : local.selected_env.topic_defaults.replication_factor
			)
			retention_ms        = coalesce(try(t.retention_ms, null), local.selected_env.topic_defaults.retention_ms)
			cleanup_policy      = coalesce(try(t.cleanup_policy, null), "delete")
			min_insync_replicas = coalesce(try(t.min_insync_replicas, null), 2)
		}
	}

	normalized_producers = [
		for p in var.producers : {
			topic_name       = p.topic_name
			topic_operations = coalesce(try(p.topic_operations, null), ["Write", "Describe", "Create"])
			principal = (
				startswith(lower(trimspace(coalesce(try(p.cn, null), var.default_principal_cn))), "user:")
				? trimspace(coalesce(try(p.cn, null), var.default_principal_cn))
				: (
					startswith(lower(trimspace(coalesce(try(p.cn, null), var.default_principal_cn))), "cn=") ||
					length(regexall("(?i),\\s*ou=", trimspace(coalesce(try(p.cn, null), var.default_principal_cn)))) > 0
					? "User:${trimspace(coalesce(try(p.cn, null), var.default_principal_cn))}"
					: "User:CN=${trimspace(coalesce(try(p.cn, null), var.default_principal_cn))},${local.principal_dn_suffix}"
				)
			)
		}
	]

	normalized_consumers = [
		for c in var.consumers : {
			topic_name       = c.topic_name
			group_id         = try(c.group_id, null)
			topic_operations = coalesce(try(c.topic_operations, null), ["Read", "Describe"])
			principal = (
				startswith(lower(trimspace(coalesce(try(c.cn, null), var.default_principal_cn))), "user:")
				? trimspace(coalesce(try(c.cn, null), var.default_principal_cn))
				: (
					startswith(lower(trimspace(coalesce(try(c.cn, null), var.default_principal_cn))), "cn=") ||
					length(regexall("(?i),\\s*ou=", trimspace(coalesce(try(c.cn, null), var.default_principal_cn)))) > 0
					? "User:${trimspace(coalesce(try(c.cn, null), var.default_principal_cn))}"
					: "User:CN=${trimspace(coalesce(try(c.cn, null), var.default_principal_cn))},${local.principal_dn_suffix}"
				)
			)
		}
	]

	topic_names             = toset(keys(local.resolved_topics))
	producer_topic_names    = toset([for p in local.normalized_producers : p.topic_name])
	consumer_topic_names    = toset([for c in local.normalized_consumers : c.topic_name])
	unknown_producer_topics = setsubtract(local.producer_topic_names, local.topic_names)
	unknown_consumer_topics = setsubtract(local.consumer_topic_names, local.topic_names)

	producer_topic_acls = {
		for x in flatten([
			for p in local.normalized_producers : [
				for operation in p.topic_operations : {
					key       = "${p.principal}|${p.topic_name}|${operation}"
					principal = p.principal
					topic     = p.topic_name
					operation = operation
				}
			]
		]) : x.key => x
	}

	producer_cluster_idempotent_acls = {
		for principal in toset([for p in local.normalized_producers : p.principal]) : principal => principal
	}

	consumer_topic_acls = {
		for x in flatten([
			for c in local.normalized_consumers : [
				for operation in c.topic_operations : {
					key       = "${c.principal}|${c.topic_name}|${operation}"
					principal = c.principal
					topic     = c.topic_name
					operation = operation
				}
			]
		]) : x.key => x
	}

	consumer_group_acls = {
		for c in local.normalized_consumers : "${c.principal}|${c.group_id}" => c
		if c.group_id != null
	}
}
