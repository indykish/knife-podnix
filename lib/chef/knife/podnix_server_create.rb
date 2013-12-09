require 'chef/knife'
require 'chef/json_compat'
require_relative 'podnix_base'

class Chef
  class Knife
    class PodnixServerCreate < Knife

      deps do
        require 'net/ssh'
        require 'net/ssh/multi'
        require 'podnix'
        require 'highline'
        require 'chef/knife/bootstrap'
        require 'chef/knife/core/bootstrap_context'
        require 'securerandom'
        require 'timeout'
        require 'socket'

        Chef::Knife.load_deps

      end
      include Knife::PodnixBase


      banner "knife podnix server create OPTIONS"

      option :name,
        :short => "-N SERVER_NAME",
        :long => "--name SERVER_NAME",
        :description => "name for the newly created Server",
        :required => true #,
       # :proc => Proc.new { |image| Chef::Config[:knife][:Podnix_server_name] = image }


      option :podnix_api_key,
        :short => "-K PODNIX_API_KEY",
        :long => "--podnix_api_key PODNIX_API_KEY",
        :description => "Podnix API key",
        :default => Chef::Config[:knife][:podnix_api_key]
        
        
      option :flavor,
        :short => "-f FLAVOR",
        :long => "--flavor FLAVOR",
        :description => "the amount of vCores and RAM that your server will get. MODEL IN PODNIX [1, 2, 4, 8], default 1",
        :required => true,
        :proc => Proc.new { |flavor| Chef::Config[:knife][:podnix_flavor] = flavor }
        
                
      option :password,
        :short => "-P PASSWORD",
        :long => "--password PASSWORD",
        :description => "Specifies the root password (on Linux) or administrator password (on Windows). Must contain at least 9 chars and include a lower case char, an upper case char and a number",
        :required => true,
        :proc => Proc.new { |password| Chef::Config[:knife][:podnix_password] = password }
        
      option :storage,
        :long => "--storage SIZE",
        :description => "Specify the size (in GB) of the system drive. Valid size is 10-250",
        :default => '10',
        :proc => Proc.new { |size| Chef::Config[:knife][:podnix_storage] = size }
        
      option :ssd,
        :long => "--ssd 1",
        :description => "If this parameter is set to 1, the system drive will be located on a SSD drive",
        :proc => Proc.new { |set| Chef::Config[:knife][:podnix_ssd] = set }

      option :image,
        :short => "-I IMAGE_ID",
        :long => "--image IMAGE_ID",
        :description => "This image_id will define operating system and pre-installed software. default '37' which is Ubuntu 13.04 (64bit), For more 'knife podnix image list' ",
        :required => true,
        :proc => Proc.new { |i| Chef::Config[:knife][:podnix_image] = i }
        
      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The user to create and add the provided public key to authorized_keys, default is 'root'",
        :default => "root"

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []


      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node default is the name of the server.",
        :proc => Proc.new { |t| Chef::Config[:knife][:chef_node_name] = t }

      def h
        @highline ||= HighLine.new
      end

      def run
        validate!

        unless config[:name]
          ui.error("A Server Name must be provided -N")
          exit 1
        end

create_hash = {
:name => "#{config[:name]}",
:model => "#{config[:flavor]}",
:image => "#{config[:image]}",
:password => "#{config[:password]}",
:storage => "#{config[:storage]}"
}
if config[:ssd]
	create_hash[:ssd] = "1"
end

        @podnix = Podnix::API.new({:key => "#{config[:podnix_api_key]}"})
        po_server = @podnix.add_server(create_hash)
          bootstrap()
puts "SERVER CREATION ================== > "
puts po_server.inspect
puts ui.color("Going to create A new server", :green)
        msg_pair("Name", config[:name])
        msg_pair("Model", config[:flavor])
        msg_pair("Image", config[:image])
        msg_pair("Storage", config[:storage])
        msg_pair("Password", config[:password])
 puts ui.color("Server is being created", :green)
      end
      
       def bootstrap
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = @server.ips
        bootstrap.config[:run_list] = locate_config_value(:run_list)
        bootstrap.config[:ssh_user] = locate_config_value(:ssh_user)
        bootstrap.config[:ssh_password] = @password
        bootstrap.config[:host_key_verify] = false
        bootstrap.config[:chef_node_name] = locate_config_value(:chef_node_name) || @server.name
        bootstrap.config[:distro] = locate_config_value(:distro)
        bootstrap.config[:use_sudo] = true unless bootstrap.config[:ssh_user] == 'root'
        bootstrap.config[:template_file] = locate_config_value(:template_file)
        bootstrap.run
        # This is a temporary fix until ohai 6.18.0 is released
        ssh("gem install ohai --pre --no-ri --no-rdoc && chef-client").run
      end
      
    
    end
  end
end
