# -------------------------------------------------------
# Confluent Cloud Environment
# -------------------------------------------------------
resource "confluent_environment" "cc_handson_env" {
  display_name = "${var.cc_env_name}-${random_id.id.hex}"
  lifecycle {
    prevent_destroy = false
  }
}

# --------------------------------------------------------
# Schema Registry
# --------------------------------------------------------
data "confluent_schema_registry_region" "cc_handson_sr" {
  cloud   = var.sr_cloud_provider
  region  = var.sr_cloud_region
  package = var.sr_package
}
resource "confluent_schema_registry_cluster" "cc_sr_cluster" {
  package = data.confluent_schema_registry_region.cc_handson_sr.package
  environment {
    id = confluent_environment.cc_handson_env.id
  }
  region {
    id = data.confluent_schema_registry_region.cc_handson_sr.id
  }
  lifecycle {
    prevent_destroy = false
  }
}

# --------------------------------------------------------
# Confluent Cloud Kafka Cluster
# --------------------------------------------------------
resource "confluent_kafka_cluster" "cc_kafka_cluster" {
  display_name = var.cc_cluster_name
  availability = var.cc_availability
  cloud        = var.cc_cloud_provider
  region       = var.cc_cloud_region
  basic {}
  environment {
    id = confluent_environment.cc_handson_env.id
  }
  lifecycle {
    prevent_destroy = false
  }
}

# --------------------------------------------------------
# Service Accounts (app_manager, sr, clients)
# --------------------------------------------------------
resource "confluent_service_account" "app_manager" {
  display_name = "cmapp-manager-${random_id.id.hex}"
  description  = local.description
  lifecycle {
    prevent_destroy = false
  }
}
resource "confluent_service_account" "sr" {
  display_name = "cmapp-sr-${random_id.id.hex}"
  description  = local.description
  lifecycle {
    prevent_destroy = false
  }
}
resource "confluent_service_account" "clients" {
  display_name = "cmapp-client-${random_id.id.hex}"
  description  = local.description
  lifecycle {
    prevent_destroy = false
  }
}

# --------------------------------------------------------
# Role Bindings (app_manager, sr, clients)
# --------------------------------------------------------
resource "confluent_role_binding" "app_manager_environment_admin" {
  principal   = "User:${confluent_service_account.app_manager.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.cc_handson_env.resource_name
  lifecycle {
    prevent_destroy = false
  }
}
resource "confluent_role_binding" "app_manager_assigner" {
  principal   = "User:${confluent_service_account.app_manager.id}"
  role_name   = "Assigner"
  crn_pattern = "${data.confluent_organization.ccloud.resource_name}/service-account=${confluent_service_account.app_manager.id}"
  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_role_binding" "sr_environment_admin" {
  principal   = "User:${confluent_service_account.sr.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.cc_handson_env.resource_name
  lifecycle {
    prevent_destroy = false
  }
}
resource "confluent_role_binding" "clients_cluster_admin" {
  principal   = "User:${confluent_service_account.clients.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.cc_kafka_cluster.rbac_crn
  lifecycle {
    prevent_destroy = false
  }
}

# --------------------------------------------------------
# Credentials / API Keys
# --------------------------------------------------------
# app_manager
resource "confluent_api_key" "app_manager_kafka_cluster_key" {
  display_name = "cmapp-manager-${var.cc_cluster_name}-key-${random_id.id.hex}"
  description  = local.description
  owner {
    id          = confluent_service_account.app_manager.id
    api_version = confluent_service_account.app_manager.api_version
    kind        = confluent_service_account.app_manager.kind
  }
  managed_resource {
    id          = confluent_kafka_cluster.cc_kafka_cluster.id
    api_version = confluent_kafka_cluster.cc_kafka_cluster.api_version
    kind        = confluent_kafka_cluster.cc_kafka_cluster.kind
    environment {
      id = confluent_environment.cc_handson_env.id
    }
  }
  depends_on = [
    confluent_role_binding.app_manager_environment_admin
  ]
  lifecycle {
    prevent_destroy = false
  }
}
# Schema Registry
resource "confluent_api_key" "sr_cluster_key" {
  display_name = "cmsr-${var.cc_cluster_name}-key-${random_id.id.hex}"
  description  = local.description
  owner {
    id          = confluent_service_account.sr.id
    api_version = confluent_service_account.sr.api_version
    kind        = confluent_service_account.sr.kind
  }
  managed_resource {
    id          = confluent_schema_registry_cluster.cc_sr_cluster.id
    api_version = confluent_schema_registry_cluster.cc_sr_cluster.api_version
    kind        = confluent_schema_registry_cluster.cc_sr_cluster.kind
    environment {
      id = confluent_environment.cc_handson_env.id
    }
  }
  depends_on = [
    confluent_role_binding.sr_environment_admin
  ]
  lifecycle {
    prevent_destroy = false
  }
}
# Kafka clients
resource "confluent_api_key" "clients_kafka_cluster_key" {
  display_name = "cm-clients-${var.cc_cluster_name}-key-${random_id.id.hex}"
  description  = local.description
  owner {
    id          = confluent_service_account.clients.id
    api_version = confluent_service_account.clients.api_version
    kind        = confluent_service_account.clients.kind
  }
  managed_resource {
    id          = confluent_kafka_cluster.cc_kafka_cluster.id
    api_version = confluent_kafka_cluster.cc_kafka_cluster.api_version
    kind        = confluent_kafka_cluster.cc_kafka_cluster.kind
    environment {
      id = confluent_environment.cc_handson_env.id
    }
  }
  depends_on = [
    confluent_role_binding.clients_cluster_admin
  ]
  lifecycle {
    prevent_destroy = false
  }
}

# --------------------------------------------------------
# Create Kafka topic users
# --------------------------------------------------------
resource "confluent_kafka_topic" "users" {
  kafka_cluster {
    id = confluent_kafka_cluster.cc_kafka_cluster.id
  }
  topic_name    = "users"
  partitions_count   = 1
  rest_endpoint = confluent_kafka_cluster.cc_kafka_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app_manager_kafka_cluster_key.id
    secret = confluent_api_key.app_manager_kafka_cluster_key.secret
  }
  lifecycle {
    prevent_destroy = false
  }
}

# --------------------------------------------------------
# Create schema for the Salesforce topic users
# --------------------------------------------------------
resource "confluent_schema" "protobuf-users" {
  schema_registry_cluster {
    id =confluent_schema_registry_cluster.cc_sr_cluster.id
  }
  rest_endpoint = confluent_schema_registry_cluster.cc_sr_cluster.rest_endpoint
  subject_name = "users-value"
  format = "PROTOBUF"
  schema = file("./schema/schema-users-value-v2.proto")
  credentials {
    key    = confluent_api_key.sr_cluster_key.id
    secret = confluent_api_key.sr_cluster_key.secret
  }

  lifecycle {
    prevent_destroy = false
  }
}


# --------------------------------------------------------
# Create Tags
# --------------------------------------------------------
resource "confluent_tag" "pii" {
  schema_registry_cluster {
    id = confluent_schema_registry_cluster.cc_sr_cluster.id
  }
  rest_endpoint = confluent_schema_registry_cluster.cc_sr_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.sr_cluster_key.id
    secret = confluent_api_key.sr_cluster_key.secret
  }

  name = "PII"
  description = "PII tag"

  lifecycle {
    prevent_destroy = false
  }
}
resource "confluent_tag" "public" {
  schema_registry_cluster {
    id = confluent_schema_registry_cluster.cc_sr_cluster.id
  }
  rest_endpoint = confluent_schema_registry_cluster.cc_sr_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.sr_cluster_key.id
    secret = confluent_api_key.sr_cluster_key.secret
  }

  name = "Public"
  description = "Public tag"

  lifecycle {
    prevent_destroy = false
  }
}
# --------------------------------------------------------
# Bind Tags to Topics
# --------------------------------------------------------
resource "confluent_tag_binding" "users" {
  schema_registry_cluster {
    id = confluent_schema_registry_cluster.cc_sr_cluster.id
  }
  rest_endpoint = confluent_schema_registry_cluster.cc_sr_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.sr_cluster_key.id
    secret = confluent_api_key.sr_cluster_key.secret
  }

  tag_name = "PII"
  entity_name = "${confluent_schema_registry_cluster.cc_sr_cluster.id}:${confluent_kafka_cluster.cc_kafka_cluster.id}:${confluent_kafka_topic.users.topic_name}"
  entity_type = "kafka_topic"

  lifecycle {
    prevent_destroy = false
  }
}

resource "null_resource" "client_properties" {
  depends_on = [
    confluent_environment.cc_handson_env,
    confluent_schema_registry_cluster.cc_sr_cluster,
    confluent_kafka_cluster.cc_kafka_cluster
  ]
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "./00_create_client.properties.sh ${confluent_api_key.sr_cluster_key.id} ${confluent_api_key.sr_cluster_key.secret} ${confluent_api_key.clients_kafka_cluster_key.id} ${confluent_api_key.clients_kafka_cluster_key.secret} ${confluent_kafka_cluster.cc_kafka_cluster.bootstrap_endpoint} ${confluent_schema_registry_cluster.cc_sr_cluster.rest_endpoint}"
  }
}