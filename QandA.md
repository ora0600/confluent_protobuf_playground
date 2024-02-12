# Questions

Here you will questions around schema management. This list is not complete.

# What is best method for protobuf?

Note that best practice for Protobuf is according to the documentation to use BACKWARD_TRANSITIVE, as adding new message types is not forward compatible. See [Docu](https://docs.confluent.io/platform/current/schema-registry/fundamentals/schema-evolution.html#:~:text=Note%20that%20best%20practice%20for,types%20is%20not%20forward%20compatible.)

# Customer want to use protobuf as event schema format. They want to use mode FULL for schema evolution. Are there any problem for old consumer to not run into serialisation issues?

Using Protobuf with the FULL schema evolution mode in a Confluent setup shouldn't cause serialization issues for old consumers as long as the changes made to the schema are backward-compatible.

When you use the FULL schema evolution mode in Confluent Schema Registry, it allows you to make backward-compatible changes to your schema, which means that existing consumers can still deserialize messages produced with the updated schema without any issues. Backward-compatible changes include:

1. Adding new fields with default values.
2. Changing the type of a field to a subtype (e.g., changing an int to a long).
3. Adding new enumeration constants to an existing enum.
4. Adding new optional fields.

However, you need to avoid making backward-incompatible changes that could lead to serialization issues for old consumers. Backward-incompatible changes include:

1. Removing fields.
2. Changing the type of a field to a supertype (e.g., changing a long to an int).
3. Renaming fields.
4. Changing the order of fields.

As long as you stick to making backward-compatible changes to your Protobuf schema and configure your Confluent Schema Registry to use the FULL schema evolution mode, old consumers should be able to deserialize messages produced with the updated schema without any problems. It's essential to carefully review your schema changes to ensure backward compatibility and conduct thorough testing to validate compatibility with existing consumers before deploying changes to a production environment.

# When to set the property use.latest.version for consumer and producer?

The property `use.latest.version` (default is false) is typically used when working with schema evolution in Apache Kafka and the Confluent Schema Registry. It allows consumers and producers to use the latest registered version of the schema for message serialization and deserialization. See [docu](https://docs.confluent.io/platform/current/schema-registry/connect.html#configuration-options). Generally speaking you can also pin the Schema ID by `use.schema.id` see [docu](https://docs.confluent.io/platform/current/schema-registry/fundamentals/serdes-develop/index.html#specifying-schema-id-and-compatibility-checks)

Here's when you might want to use it:

1. Consumer Side:
When you have consumers that need to dynamically adapt to schema changes without needing manual intervention.
When you want your consumers to automatically use the latest version of the schema registered in the Schema Registry.
2. Producer Side:
When you have producers that need to produce messages using the latest schema version available in the Schema Registry.
When you want to ensure that all produced messages are serialized using the most up-to-date schema definition.

Setting `use.latest.version` to true on both the producer and consumer side ensures that they always use the latest schema version available in the registry. This can be useful in dynamic environments where schemas might evolve frequently, and you want your applications to seamlessly handle those changes without manual intervention.

However, **keep in mind that blindly using the latest schema version might lead to compatibility issues** if the changes are not backward-compatible. It's essential to understand your schema evolution strategy and ensure that new versions are backward-compatible to avoid breaking existing consumers.

# If I set on producer `use.latest.version` to false and try to get the schema from object what do I need to care of?

If you set `use.latest.version` to false on the producer side and you want to manually specify the schema for message serialization, you'll need to handle schema versioning and schema management yourself. Here are a few things to consider:

0. Retrieve Schema by Version: You need to retrieve the specific version of the schema you want to use for serialization. This involves querying the Schema Registry to fetch the schema by its version number.
1. Specify Schema Version: You'll need to specify the exact schema version you want to use for serialization. This means you need to keep track of schema versions and explicitly specify the version number in your producer code.
2. Schema Compatibility: Ensure that the schema version you specify is compatible with the messages you are producing. If the schema version is not compatible, it may lead to serialization errors or incorrect data being sent to Kafka.
3. Schema Registration: You'll need to ensure that the schema is registered in the Schema Registry before you attempt to use it for serialization. If the schema is not registered, you won't be able to retrieve it by version number.
4. Handling Schema Evolution: If your schema evolves over time, you'll need to manage schema evolution manually. This includes registering new schema versions in the Schema Registry and updating your producer code to use the latest compatible schema version.
5. Error Handling: Make sure to handle errors gracefully, especially when retrieving schemas or serializing messages. If there are any issues with schema retrieval or serialization, your producer should handle them appropriately to avoid data loss or inconsistencies.

Overall, manually managing schema versions and serialization adds complexity to your producer code. It's generally more convenient to use use.latest.version set to true if your use case allows it, as it automates schema management and ensures compatibility with the latest schema version. However, if you have specific requirements or constraints that necessitate manual schema versioning, you'll need to carefully handle these aspects in your producer code.

Here's an example of how you might configure the producer to use a specific schema version in Python using the confluent_kafka library:

```python
from confluent_kafka import Producer, KafkaError

# Kafka broker configuration
bootstrap_servers = '<YOUR_BOOTSTRAP_SERVERS>'
topic = 'user-topic'

# Schema version to use for serialization
schema_version = 1  # Example: specify the schema version you want to use

# Create a Kafka producer
producer = Producer({
    'bootstrap.servers': bootstrap_servers,
    'schema.registry.url': '<SCHEMA_REGISTRY_URL>',
    'use.latest.version': False,  # Ensure this is set to False
    'use.schema.id': schema_version  # Specify the schema version to use
})

# Produce messages using the specified schema version
# Your producer logic goes here...
``` 

# Protobuf: When forward compatibility method is not achievable for protobuf?

In the context of schema evolution with Protobuf, the **"forward compatibility"** refers to the ability to read new data with an old schema. It means that if a new field is added to a message, an old consumer that's unaware of this new field should still be able to read and process the message without errors, ignoring the new field.

However, there are situations where achieving forward compatibility with Protobuf schemas may not be feasible or practical:

1. **Semantic Changes**: Forward compatibility becomes challenging when there are semantic changes to the message structure. For example, if the meaning of an existing field changes, or if the interpretation of the message content changes, it may not be possible for old consumers to correctly process the new messages even if the schema technically remains backward-compatible.
2. **Non-Optional Fields**: If a new required field is added to a message, old consumers will not be able to read the new messages without breaking compatibility. This is because required fields must be present in all messages, and old consumers won't be aware of the new required field, leading to deserialization errors.
3. **Enum Changes**: Modifying or reordering enum values in a Protobuf schema can break forward compatibility if old consumers rely on specific enum values or their order. Adding new enum values without removing existing ones is generally safe for forward compatibility.
4. **Backward-Incompatible Changes**: Any backward-incompatible change to the schema will obviously break forward compatibility. This includes removing fields, changing field types in incompatible ways, or changing field IDs.
5. **Complex Evolution Scenarios**: In some complex schema evolution scenarios, achieving forward compatibility without breaking changes may not be feasible due to the nature of the changes or the requirements of the application.

In summary, achieving forward compatibility with Protobuf schemas depends on the nature of the changes made to the schema and the requirements of the application. While Protobuf provides mechanisms for handling backward-compatible schema changes, achieving forward compatibility may not always be possible or practical, especially in scenarios involving semantic changes or non-optional field additions.

# Some Hints, when to use which method:

1. **Forward compatibility** is enough when the producer wants to update events without breaking consumers, who still would be able to use the old schema before they update.
2. **Alternatively**, you might want to update consumers first. If that’s your preferred ordering, it’s **backward compatibility** you’ll need to keep. Such an approach is mentioned in the Avro and Schema Registry documentation, check it out for a deeper dive.
3. **Full compatibility** is the most restrictive variant. It is recommended when we want to make sure that even after adjusting consumers to the latest schema, they still will be able to parse older events and have special handling for fields with present or missing values. Choose this approach when you expect historical events to be replayed, allowing correct handling of all older versions by the consumers, for example, in event sourcing.

back to [main](ReadMe.md)