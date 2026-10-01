output "selected_environment" {
  description = "Environment selected for this run."
  value       = local.environment
}

output "resolved_bootstrap_server" {
  description = "Bootstrap server used by the provider after environment mapping/override."
  value       = local.bootstrap_server
}

output "resolved_command_config_path" {
  description = "Command config path resolved from environment mapping/override."
  value       = local.command_config_path
}

output "resolved_topics" {
  description = "Final topic values after applying environment defaults and DLT rules."
  value       = local.resolved_topics
}
