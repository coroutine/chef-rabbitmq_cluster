maintainer       "bradmontgomery"
maintainer_email "bmontgomery@coroutine.com"
license          "Apache 2.0"
description      "Recipes to build an RabbitMQ Cluster"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.5"

recipe           "rabbitmq_cluster", "Creates a RabbitMQ Cluster"
recipe           "rabbitmq_cluster::default", "Creates a RabbitMQ Cluster"
recipe           "rabbitmq_cluster::setup", "Sets up RabbitMQ Vhosts, Users, and Permissions"

depends "rabbitmq"

%w{ ubuntu debian }.each do |os|
  supports os
end
