#!/usr/bin/env python
# =============================================================================
#
# Helper module
# Original source code https://github.com/confluentinc/examples/blob/7.5.0-post/clients/cloud/python/ccloud_lib.py
# =============================================================================

import argparse, sys
from jproperties import Properties

def parse_args():
    """Parse command line arguments"""

    parser = argparse.ArgumentParser(
        description="Confluent Python Client example to consume messages to Confluent Cloud"
    )
    parser._action_groups.pop()
    required = parser.add_argument_group("required arguments")
    required.add_argument(
        "-f",
        dest="config_file",
        help="path to Confluent Cloud configuration file",
        required=True,
    )
    required.add_argument("-t", dest="topic", help="topic name", required=True)
    args = parser.parse_args()

    return args


def read_ccloud_config(config_file):
    """Read Confluent Cloud configuration for librdkafka clients"""

    conf = {}
    with open(config_file) as fh:
        for line in fh:
            line = line.strip()
            if len(line) != 0 and line[0] != "#":
                parameter, value = line.strip().split("=", 1)
                conf[parameter] = value.strip()

    return conf


def pop_schema_registry_params_from_config(conf):
    """Remove potential Schema Registry related configurations from dictionary"""

    conf.pop("schema.registry.url", None)
    conf.pop("basic.auth.user.info", None)
    conf.pop("basic.auth.credentials.source", None)

    return conf