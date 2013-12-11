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
        :required => true 
              
      option :bootstrap,
        :long => "--[no-]bootstrap",
        :description => "Bootstrap the server with knife bootstrap",
        :boolean => true,
        :default => true

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
        
      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template; default is 'chef-full'",
        :proc => Proc.new { |d| Chef::Config[:knife][:distro] = d },
        :default => "chef-full"
        

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node default is the name of the server.",
        :proc => Proc.new { |t| Chef::Config[:knife][:chef_node_name] = t }

      def h
        @highline ||= HighLine.new
      end

      def podnix_api
        Podnix::API.new({:key => "#{config[:podnix_api_key]}"})
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

        @po_server = podnix_api.add_server(create_hash)

        puts ui.color("Server:", :green)
        msg_pair("Name", config[:name])
        msg_pair("Model", config[:flavor])
        msg_pair("Image", config[:image])
        msg_pair("Storage", config[:storage])
        msg_pair("Password", config[:password])

        puts ui.color("Server is being created", :green)
        puts ui.color("Creating Server......", :green)

        sleep 60

        #podnix_api = Podnix::API.new({:key => "#{config[:podnix_api_key]}"})
        @po_start = podnix_api.start_server({:id => "#{@po_server.data[:body]['id']}"})
        puts ui.color("Starting Server......", :green)
        sleep 60

        @po_get = podnix_api.get_server({:id => "#{@po_server.data[:body]['id']}"})
        print "\n#{ui.color("Waiting for instance", :magenta)}"

        puts("\n")
        @po_server = @po_get.data[:body]['data']
        msg_pair("Public DNS Name", @po_server['hostname'])
        msg_pair("Public IP Address", @po_server['ip'])

        bootstrap()

        puts "\n"
        msg_pair("ID", @po_server['id'])
        msg_pair("Name", @po_server['name'])
        msg_pair("Image", @po_server['image'])
        msg_pair("Password", @po_server['vnc_passwd'])
        msg_pair("vCores", @po_server['vcores'])
        msg_pair("RAM", @po_server['ram'])
        msg_pair("Model", @po_server['model'])
        msg_pair("Drives", @po_server['drives'])
        msg_pair("Storage", @po_server['storage'])
        msg_pair("Run List", (config[:run_list]))
        #msg_pair("JSON Attributes",config[:json_attributes]) unless !config[:json_attributes] || config[:json_attributes].empty?
      end
      #=end

      def bootstrap
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = @po_server['ip']
        bootstrap.config[:run_list] = locate_config_value(:run_list)
        bootstrap.config[:ssh_user] = locate_config_value(:ssh_user)
        bootstrap.config[:ssh_password] = locate_config_value(:password)
        bootstrap.config[:distro] = locate_config_value(:distro)
        bootstrap.config[:host_key_verify] = false
        bootstrap.config[:chef_node_name] = locate_config_value(:chef_node_name) || @po_server['name']
        bootstrap.config[:use_sudo] = true unless bootstrap.config[:ssh_user] == 'root'
        bootstrap.run
      end

    end
  end
end
