Description
===========
This cookbook defines recipes to configure a RabbitMQ Cluster and setup
up users/permissions/vhosts.

Requirements
============
This cookbook requires the following Opscode cookbooks:

* [rabbitmq](https://github.com/opscode/cookbooks/tree/master/rabbitmq)

Attributes
==========
This cookbook defines the following attribute for RabbitMQ:

    node[:rabbitmq_setup_items] = []

Override this in a role, and include a list of items from the `rabbitmq` data bag. These will define the vhosts, users, and permissions that get created in RabbitMQ. (Read the recipe info below for an example).

The Opscode rabbitmq cookbooks use the attributes defined by the Opscode cookbook. Specifically, information for clustering should be provided. So, you may include something like the following in a Role:

    override_attributes(
      "rabbitmq" => {
        "cluster" => "yes",
        "cluster_config" => "/etc/rabbitmq/rabbitmq.config",
        "erlang_cookie" => "REPLACETHISWITHYOUROWN",
        "cluster_disk_nodes" => ['node01', 'node02']  
      },
      "rabbitmq_setup_items" => ['node01_permissions', 'node02_permissions']
    )

Note that the elements of `cluster_disk_nodes` are Chef node names. Each of these nodes must also have entries in `/etc/hosts` (see the [chef-hosts](https://github.com/coroutine/chef-hosts) cookbook).

Usage
=====
The following recipes are defined:

* `default` - Installs RabbitMQ (using the Opscode recipe), and sets up a cluster
* `setup` - Create vhosts, users, and permissions based on items from the `rabbitmq` data bag

`default`
---------
Setting up a RabbitMQ cluster is a little tricky. First you have bootstrap the nodes that will participate in the cluster, and they must all be able to communicate with each other using a host alias. Therefore, this is a multi-step process:

1. Boostrap the nodes, making sure they can talk to each other. 
2. After the nodes are live, re-run `chef-client` (`knife ssh name:NODENAME -a ipaddress -x USER -P PASSWORD "sudo chef-client"`) to make sure `/etc/hosts` is complete. Verify with something like `knife ssh name:NODENAME -a ipaddress -x USER -P PASSWORD "cat /etc/hosts"`
3. Create a role that includes the `rabbitmq_cluster` recipe. This role should override the attributes (see the `rabbitmq` attributes listed above) for each node that participates in the cluster. Add this role to each node using `knife node run_list add NODENAME "role[ROLENAME]"`, then re-run `chef-client` on each node.
4. At this point, the cluster should be configured. You can verify this by running the `rabbitmqctl cluster_status` command on each node.

`setup`
-------
This recipe creates users, vhosts, and sets permissions for RabbitMQ. It reads data from the `rabbitmq` data bag. Each item in the data bag should define `vhosts`, `users` and any permissions a user should have for each `vhost`. 

Additionally, you can specify a `guest_password` which will change the password for the default `guest` account, OR you can set `delete_guest` to `true` and the default account will be removed.

An item in the `rabbitmq` data bag (`example_item.json`) would look something like this:

    {
        "id": "example_item",
        "delete_guest": true,
        "guest_password": "",
        "vhosts": [
            "/sample_vhost"
        ],
        "users": [
            {
                "name":"user_one",
                "password":"secret-thing-here",
                "permissions": [
                    {
                        "vhost":"/sample_vhost",
                        "permissions":"\".*\" \".*\" \".*\""
                    }
                ]
            }
        ]
    }

Then, to apply this data to a node, you would create a role (e.g. `rabbitmq_setup`) that looked something like the following:

    name "rabbitmq_setup"
    description "Vhost and User config for RabbitMQ"
    run_list(
      "recipe[rabbitmq_cluster::setup]"
    )
    default_attributes(
      "rabbitmq_setup_items" => ['example_item', ]
    )

