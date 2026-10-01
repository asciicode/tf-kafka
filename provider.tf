provider "kafka" {
  bootstrap_servers = [local.bootstrap_server]

  tls_enabled     = var.kafka_tls_enabled
  skip_tls_verify = var.kafka_skip_tls_verify

  ca_cert     = var.kafka_ca_cert
  client_cert = var.kafka_client_cert
  client_key  = var.kafka_client_key

  sasl_username  = var.kafka_sasl_username
  sasl_password  = var.kafka_sasl_password
  sasl_mechanism = var.kafka_sasl_mechanism
}
