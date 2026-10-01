variable "environment" {
	description = "Target environment: DEV, QA, PREPROD, or PROD."
	type        = string

	validation {
		condition     = contains(["DEV", "QA", "PREPROD", "PROD"], upper(var.environment))
		error_message = "environment must be one of: DEV, QA, PREPROD, PROD."
	}
}

variable "bootstrap_server_override" {
	description = "Optional override for bootstrap server host:port."
	type        = string
	default     = null
}

variable "command_config_path_override" {
	description = "Optional override for command config path from environment defaults (kept for parity with existing CLI workflow)."
	type        = string
	default     = null
}

variable "kafka_tls_enabled" {
	description = "Enable TLS for Kafka broker connections."
	type        = bool
	default     = true
}

variable "kafka_skip_tls_verify" {
	description = "Skip TLS certificate verification (not recommended outside local troubleshooting)."
	type        = bool
	default     = false
}

variable "kafka_ca_cert" {
	description = "Optional CA certificate content for broker TLS validation."
	type        = string
	default     = null
}

variable "kafka_client_cert" {
	description = "Optional client certificate content for mTLS."
	type        = string
	default     = null
	sensitive   = true
}

variable "kafka_client_key" {
	description = "Optional client private key content for mTLS."
	type        = string
	default     = null
	sensitive   = true
}

variable "kafka_sasl_username" {
	description = "Optional SASL username (for SCRAM/PLAIN)."
	type        = string
	default     = null
}

variable "kafka_sasl_password" {
	description = "Optional SASL password (for SCRAM/PLAIN)."
	type        = string
	default     = null
	sensitive   = true
}

variable "kafka_sasl_mechanism" {
	description = "Optional SASL mechanism (for example: scram-sha256, scram-sha512, plain)."
	type        = string
	default     = null

	validation {
		condition = var.kafka_sasl_mechanism == null || contains([
			"plain",
			"scram-sha256",
			"scram-sha512"
		], try(lower(var.kafka_sasl_mechanism), ""))
		error_message = "kafka_sasl_mechanism must be one of: plain, scram-sha256, scram-sha512 (or null)."
	}
}

variable "default_principal_cn" {
	description = "Default CN used when producer/consumer cn is omitted."
	type        = string
	default     = "core-sc-allocations-processor"
}

variable "principal_ou" {
	description = "Default principal OU for CN-only inputs."
	type        = string
	default     = "IT"
}

variable "principal_org" {
	description = "Default principal organization for CN-only inputs."
	type        = string
	default     = "Foodstuffs North Island"
}

variable "principal_state" {
	description = "Default principal state for CN-only inputs."
	type        = string
	default     = "Auckland"
}

variable "principal_country" {
	description = "Default principal country for CN-only inputs."
	type        = string
	default     = "NZ"
}

variable "topics" {
	description = "Topics to create. Mandatory fields by use-case are topic name and environment."
	type = list(object({
		name                = string
		partitions          = optional(number)
		replication_factor  = optional(number)
		retention_ms        = optional(number)
		cleanup_policy      = optional(string)
		min_insync_replicas = optional(number)
	}))
	default = []

	validation {
		condition     = alltrue([for t in var.topics : length(trimspace(t.name)) > 0])
		error_message = "Each topic must have a non-empty name."
	}
}

variable "producers" {
	description = "Producer ACL inputs. topic_name is mandatory. cn can be CN-only, full DN, or omitted to use default_principal_cn."
	type = list(object({
		cn               = optional(string)
		topic_name       = string
		topic_operations = optional(list(string))
	}))
	default = []

	validation {
		condition = alltrue([
			for p in var.producers :
			length(trimspace(p.topic_name)) > 0 && (try(p.cn, null) == null || length(trimspace(p.cn)) > 0)
		])
		error_message = "Each producer entry must include non-empty topic_name, and cn must be non-empty when provided."
	}

	validation {
		condition = alltrue([
			for p in var.producers :
			try(p.topic_operations, null) == null || alltrue([
				for op in coalesce(try(p.topic_operations, null), []) : contains([
					"Write",
					"Describe",
					"Create",
					"Alter",
					"Delete"
				], op)
			])
		])
		error_message = "producer.topic_operations supports only: Write, Describe, Create, Alter, Delete."
	}
}

variable "consumers" {
	description = "Consumer ACL inputs. topic_name is mandatory. group_id is optional (only needed for Group ACL). cn can be CN-only, full DN, or omitted to use default_principal_cn."
	type = list(object({
		cn               = optional(string)
		group_id         = optional(string)
		topic_name       = string
		topic_operations = optional(list(string))
	}))
	default = []

	validation {
		condition = alltrue([
			for c in var.consumers :
			length(trimspace(c.topic_name)) > 0 &&
			(try(c.cn, null) == null || length(trimspace(c.cn)) > 0) &&
			(try(c.group_id, null) == null || length(trimspace(c.group_id)) > 0)
		])
		error_message = "Each consumer entry must include non-empty topic_name; cn and group_id must be non-empty when provided."
	}

	validation {
		condition = alltrue([
			for c in var.consumers :
			try(c.topic_operations, null) == null || alltrue([
				for op in coalesce(try(c.topic_operations, null), []) : contains([
					"Read",
					"Describe",
					"Create",
					"Write",
					"Alter",
					"Delete"
				], op)
			])
		])
		error_message = "consumer.topic_operations supports only: Read, Describe, Create, Write, Alter, Delete."
	}
}
