#
# Cookbook Name:: rabbitmq_cluster
# Recipe:: setup
#
# Copyright 2012, Coroutine
#
# All rights reserved.
#

# Pulls the appropriate configs from the "rabbitmq" data bag.
# These should be specified in a role.
node['rabbitmq_setup_items'].each do |item_name|
  search(:rabbitmq, "id:#{item_name}") do |config|

    # Create a Vhosts
    config['vhosts'].each do |vhost|
      rabbitmq_vhost vhost do
        action :add
      end
      Chef::Log.info "Created RabbitMQ vhost: #{vhost}"
    end

    # Create Users
    config['users'].each do |user|
      rabbitmq_user user['name'] do
        password user['password']
        action :add
      end
      Chef::Log.info "Created RabbitMQ user: #{user['name']}"

      # Assign permissions
      user['permissions'].each do |perms|
        rabbitmq_user user['name'] do 
          if not perms['vhost'].empty?
            vhost perms['vhost']
          end
          permissions perms['permissions']
          action :set_permissions
          Chef::Log.info "Set RabbitMQ permissions for #{user['name']} on #{perms['vhost']}"
        end
      end
    end
   
    # Delete or update the default guest account
    if config['delete_guest']
      rabbitmq_user "guest" do
        action :delete
      end
      Chef::Log.info "Deleted RabbitMQ guest account"
    elsif not config['guest_password'].empty?
      bash "reset guest password" do
        user "root"
        code <<-EOH
          rabbitmqctl change_password guest #{config['guest_password']} 
        EOH
      end
      Chef::Log.info "Reset password for RabbitMQ guest account"
    end
    
  end
end

