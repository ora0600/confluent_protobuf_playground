# #####
# See confluent sample here: https://github.com/confluentinc/confluent-kafka-python/blob/master/examples/protobuf_producer.py
# usage: python3 protobuf_consumer.py -f client.properties -t users
# ######
import argparse

# Protobuf generated class; resides at ./schema/schema_users_value_v2_pb2.py
import schema.schema_users_value_v2_pb2 as user_pb2
from confluent_kafka import Consumer
from confluent_kafka.serialization import StringSerializer, SerializationContext, MessageField
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.protobuf import ProtobufDeserializer
import ccloud_lib

if __name__ == '__main__':
    # Read arguments and configurations and initialize
    args = ccloud_lib.parse_args()
    config_file = args.config_file
    topic = args.topic
    confconsumer = ccloud_lib.read_ccloud_config(config_file)

    schema_registry_conf = {
        "url": confconsumer["schema.registry.url"],
        "basic.auth.user.info": confconsumer["basic.auth.user.info"],
    }
    schema_registry_client = SchemaRegistryClient(schema_registry_conf)
    
    protobuf_deserializer = ProtobufDeserializer(user_pb2.User,
                                                 {'use.deprecated.format': False})
    
    consumer_conf = ccloud_lib.pop_schema_registry_params_from_config(confconsumer)
    
    consumer = Consumer(consumer_conf)
    consumer.subscribe([topic])

    print("Consuming users records from topic {}. ^C to exit.".format(topic))
    while True:
        try:
            # SIGINT can't be handled when polling, limit timeout to 1 second.
            msg = consumer.poll(1.0)
            if msg is None:
                continue

            user = protobuf_deserializer(msg.value(), SerializationContext(topic, MessageField.VALUE))

            if user is not None:
                print("User record {}:\n"
                      "\tname: {}\n"
                      "\tfavorite_number: {}\n"
                      "\tfavorite_color: {}\n"
                      .format(msg.key(), user.name,
                              user.favorite_number,
                              user.favorite_color))
        except KeyboardInterrupt:
            break

    consumer.close()

