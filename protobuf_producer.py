# #####
# See confluent sample here: https://github.com/confluentinc/confluent-kafka-python/blob/master/examples/protobuf_producer.py
# usage: python3 protobuf_producer.py -f client.properties -t users
# ######
import argparse
from uuid import uuid4

# Protobuf generated class; resides at ./schema/schema_users_value_v2_pb2.py
import schema.schema_users_value_v2_pb2 as user_pb2
from confluent_kafka import Producer
from confluent_kafka.serialization import StringSerializer, SerializationContext, MessageField
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.protobuf import ProtobufSerializer
import ccloud_lib

def delivery_report(err, msg):
    """
    Reports the failure or success of a message delivery.

    Args:
        err (KafkaError): The error that occurred on None on success.
        msg (Message): The message that was produced or failed.
    """

    if err is not None:
        print("Delivery failed for User record {}: {}".format(msg.key(), err))
        return
    print('User record {} successfully cons to {} [{}] at offset {}'.format(
        msg.key(), msg.topic(), msg.partition(), msg.offset()))

if __name__ == '__main__':
    # Read arguments and configurations and initialize
    args = ccloud_lib.parse_args()
    config_file = args.config_file
    topic = args.topic
    confproducer = ccloud_lib.read_ccloud_config(config_file)

    schema_registry_conf = {
        "url": confproducer["schema.registry.url"],
        "basic.auth.user.info": confproducer["basic.auth.user.info"]
    }
    schema_registry_client = SchemaRegistryClient(schema_registry_conf)
    
    string_serializer = StringSerializer('utf8')
    # Parameters see https://github.com/confluentinc/confluent-kafka-python/blob/master/src/confluent_kafka/schema_registry/protobuf.py
    protobuf_serializer_conf = {'use.deprecated.format': False, 
                                'use.latest.version': False, 
                                'normalize.schemas': True}
    protobuf_serializer = ProtobufSerializer(user_pb2.User,
                                             schema_registry_client,
                                             protobuf_serializer_conf)
    
    producer_conf = ""
    producer_conf = ccloud_lib.pop_schema_registry_params_from_config(confproducer)
    producer = Producer(producer_conf)
    
    # Print all properties of the producer
    print("Producer Client Configuration:")
    for key, value in producer_conf.items():
        print(f"{key}: {value}")
    # Print all properties of the producer
    print("Producer Client Serialization Configuration:")
    for key, value in protobuf_serializer_conf.items():
        print(f"{key}: {value}")
    print("Producer Client Default Serialization Configuration:")
    for key, value in protobuf_serializer._default_conf.items():
        print(f"{key}: {value}")
    
    print("Producing user records to topic {}. ^C to exit.".format(topic))
    while True:
        # Serve on_delivery callbacks from previous calls to produce()
        producer.poll(0.0)
        try:
            user_name = input("Enter name: ")
            user_favorite_number = int(input("Enter favorite number: "))
            user_favorite_color = input("Enter favorite color: ")
            user = user_pb2.User(name=user_name,
                                 favorite_color=user_favorite_color,
                                 favorite_number=user_favorite_number)
            producer.produce(topic=topic, partition=0,
                             key=string_serializer(str(uuid4())),
                             value=protobuf_serializer(user, SerializationContext(topic, MessageField.VALUE)),
                             on_delivery=delivery_report)
        except (KeyboardInterrupt, EOFError):
            break
        except ValueError:
            print("Invalid input, discarding record...")
            continue

    print("\nFlushing records...")
    producer.flush()

