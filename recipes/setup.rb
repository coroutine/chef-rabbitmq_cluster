#
# Cookbook Name:: rabbitmq_cluster
# Recipe:: setup
#
# Copyright 2012, Coroutine LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
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

