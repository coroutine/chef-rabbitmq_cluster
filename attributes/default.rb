#
# Cookbook Name:: rabbitmq_cluster
# Attributes:: default
#
# Copyright 2012, Coroutine
#
# All rights reserved.

# The access (user/vhost) configs for a RabbitMQ 
# node. This should be a list of items stored in
# the `rabbitmq` data bag

default[:rabbitmq_setup_items] = []
