#
# Cookbook Name:: rabbitmq_cluster
# Recipe:: default
#
# Copyright 2012, Coroutine
#
# All rights reserved.
#
# NOTE: all queue nodes need to know each other by 
# their short names! You can add entries in /etc/hosts
# to make this happen.

# Make sure RabbitMQ is installed
include_recipe "rabbitmq::default"

# Make sure rabbitmq-server is NOT running before 
# attempting to use the rabbitmq::cluster recipe, since 
# changing the .erlang.cookie will prevent you from 
# stopping/starting the service in the future.
service "rabbitmq-server" do
  stop_command "service rabbitmq-server stop"
  action :stop
  only_if 'service rabbitmq-server status'
end

template "/var/lib/rabbitmq/.erlang.cookie" do
  source "rabbitmq_doterlang.cookie.erb"
  owner "rabbitmq"
  group "rabbitmq"
  mode 0600
end

template "/etc/rabbitmq/rabbitmq.config" do
  source "rabbitmq.config.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, resources(:service => "rabbitmq-server")
end

# Blow away the mnesia database. This is necessary 
# so the nodes in the cluster will be able to 
# recognize each other (this should only happen once)
bash "Reset mnesia" do
  user "root"
  cwd "/var/lib/rabbitmq"
  code <<-EOH
    rm -rf mnesia/
    touch .reset_mnesia_database
  EOH
  not_if do
    File.exists?("/var/lib/rabbitmq/.reset_mnesia_database")
  end
end

# Restart the server. 
bash "Restart RabbitMQ" do
  user "root"
  code <<-EOH
    service rabbitmq-server restart
  EOH
end
