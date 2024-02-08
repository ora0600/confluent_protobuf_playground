
output "A03_cc_sr_cluster" {
  description = "CC SR Cluster ID"
  value       = resource.confluent_schema_registry_cluster.cc_sr_cluster.id
}

output "A04_cc_sr_cluster_endpoint" {
  description = "CC SR Cluster ID"
  value       = resource.confluent_schema_registry_cluster.cc_sr_cluster.rest_endpoint
}

output "A05_cc_kafka_cluster" {
  description = "CC Kafka Cluster ID"
  value       = resource.confluent_kafka_cluster.cc_kafka_cluster.id
}

output "A06_cc_kafka_cluster_bootsrap" {
  description = "CC Kafka Cluster ID"
  value       = resource.confluent_kafka_cluster.cc_kafka_cluster.bootstrap_endpoint

}

output "D_01_SRKey" {
  description = "CC SR Key"
  value       = confluent_api_key.sr_cluster_key.id
}
output "D_02_SRSecret" {
  description = "CC SR Secret"
  value       = confluent_api_key.sr_cluster_key.secret
  sensitive = true
}

output "D_03_AppManagerKey" {
  description = "CC AppManager Key"
  value       = confluent_api_key.app_manager_kafka_cluster_key.id
}

output "D_04_AppManagerSecret" {
  description = "CC AppManager Secret"
  value       = confluent_api_key.app_manager_kafka_cluster_key.secret
  sensitive = true
}

output "D_05_ClientKey" {
  description = "CC clients Key"
  value       = confluent_api_key.clients_kafka_cluster_key.id
}
output "D_06_ClientSecret" {
  description = "CC Client Secret"
  value       = confluent_api_key.clients_kafka_cluster_key.secret
  sensitive = true
}

output "E01_BlockStart" {
  value = "***********************************************************************************************************"
}

output "E02_Playground" {
  value = "Start Python Client and play see what is happening, all schema set and events are moving? \n python3 protobuf_producer.py -f client.properties -t users"
}

output "E03_DoSchemaEvolution" {
  value = "Login into Confluent Cloud and play schema, add new fields etc. and see what is happening."
}  

output "E03_Playground" {
  value = "See what the consumer will do:  \n python3 protobuf_consumer.py -f client.properties -t users"
}  
output "E04_BlockEnd" {
  value = "***********************************************************************************************************"
}
