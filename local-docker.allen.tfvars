environment = "DEV"

# Use host-mapped Kafka port for local runs.
bootstrap_server_override = "localhost:9092"

# Local Kafka in docker-compose is plaintext by default.
kafka_tls_enabled = false

topics = [
  {
    name = "allen.tf"
    # Local single-node Kafka requires replication factor 1.
    replication_factor = 1
    partitions         = 1
  },
  {
    name               = "allen.tf.dlt"
    replication_factor = 1
    partitions         = 1
  }
]

producers = [
  {
    cn         = "core-allen-p"
    topic_name = "allen.tf"
    topic_operations = ["Write", "Describe", "Create"]
  }
]

consumers = [
  {
    cn         = "core-allen-c"
    group_id   = "allen-group"
    topic_name = "allen.tf"
  }
]
