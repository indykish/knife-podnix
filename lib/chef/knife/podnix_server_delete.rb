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

      option :datacenter_name,
        :short => "-D DATACENTER_NAME",
        :long => "--data-center DATACENTER_NAME",
        :description => "The datacenter where the server will be created",
        :proc => Proc.new { |datacenter| Chef::Config[:knife][:Podnix_datacenter] = datacenter }

      option :name,
        :long => "--name SERVER_NAME",
        :description => "name for the newly created Server",
        :proc => Proc.new { |image| Chef::Config[:knife][:Podnix_server_name] = image }

      option :memory,
        :long => "--ram RAM",
        :description => "Amount of Memory in MB of the new Server",
        :proc => Proc.new { |memory| Chef::Config[:knife][:Podnix_memory] = memory }

      option :cpus,
        :long => "--cpus CPUS",
        :description => "Amount of CPUs of the new Server",
        :proc => Proc.new { |cpus| Chef::Config[:knife][:Podnix_cpus] = cpus }

      option :hdd_size,
        :long => "--hdd-size GB",
        :description => "Size of storage in GB",
        :default => 25

      option :bootstrap,
        :long => "--[no-]bootstrap",
        :description => "Bootstrap the server with knife bootstrap",
        :boolean => true,
        :default => true

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The user to create and add the provided public key to authorized_keys, default is 'root'",
        :default => "root"

      option :identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication",
        :default => "#{File.expand_path('~')}/.ssh/id_rsa"

      option :image_name,
        :short => "-i IMAGE_NAME",
        :long => "--image-name IMAGE_NAME",
        :description => "The image name which will be used to create the server, default is 'Ubuntu-12.04-LTS-server-amd64-06.21.13.img'",
        :default => 'Ubuntu-12.04-LTS-server-amd64-06.21.13.img'

      option :snapshot_name,
        :short => '-S SNAPSHOT_NAME',
        :long => "--snaphot-name SNAPSHOT_NAME",
        :description => "The snapshot name which will be used to create the server (can not be used with the image-name option)",
        :proc => Proc.new { |s| Chef::Config[:knife][:Podnix_snapshot_name] = s }

      option :public_key_file,
        :short => "-k PUBLIC_KEY_FILE",
        :long => "--public-key-file PUBLIC_KEY_FILE",
        :description => "The SSH public key file to be added to the authorized_keys of the given user, default is '~/.ssh/id_rsa.pub'",
        :default => "#{File.expand_path('~')}/.ssh/id_rsa.pub"

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template; default is 'ubuntu12.04-gems'",
        :proc => Proc.new { |d| Chef::Config[:knife][:distro] = d },
        :default => "ubuntu12.04-gems"

      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use",
        :proc => Proc.new { |t| Chef::Config[:knife][:template_file] = t },
        :default => false

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
        configure

        unless Chef::Config[:knife][:Podnix_datacenter]
          ui.error("A Datacenter must be specified")
          exit 1
        end

        unless Chef::Config[:knife][:Podnix_server_name]
          ui.error("You need to provide a name for the server")
          exit 1
        end

        ui.info "Going to create a new server"
        msg_pair("Name", Chef::Config[:knife][:Podnix_server_name])
        msg_pair("Datacenter", Chef::Config[:knife][:Podnix_datacenter])
        msg_pair("Image", Chef::Config[:knife][:Podnix_image])
        msg_pair("CPUs", Chef::Config[:knife][:Podnix_cpus] || 1)
        msg_pair("Memory", Chef::Config[:knife][:Podnix_memory] || 1024)

        puts "#{ui.color("Locating Datacenter", :magenta)}"
        @dc = DataCenter.find(:name => Chef::Config[:knife][:Podnix_datacenter])
        @dc.wait_for_provisioning

        # DELETEME for debugging only
        #@dc.clear
        #@dc.wait_for_provisioning
        # DELETEME

        create_server()

        change_password()
        @password = @new_password
        puts ui.color("Changed the password successfully", :green)

        upload_ssh_key

        if config[:bootstrap]
          bootstrap()
        end

        msg_pair("ID", @server.id)
        msg_pair("Name", @server.name)
        msg_pair("Datacenter", @dc.name)
        msg_pair("CPUs", @server.cores.to_s)
        msg_pair("RAM", @server.ram.to_s)
        msg_pair("IPs", (@server.respond_to?("ips") ? @server.ips : ""))
      end

      def create_server
        @password = SecureRandom.hex.gsub(/[i|l|0|1|I|L]/,'')
        @new_password = SecureRandom.hex.gsub(/[i|l|0|1|I|L]/,'')

        storage_options = {:size => locate_config_value(:hdd_size),
                           :data_center_id => @dc.id}
        if locate_config_value(:Podnix_snapshot_name)
          puts "#{ui.color("Locating Snapshot", :magenta)}"
          @snapshot = Snapshot.find(:name => locate_config_value(:Podnix_snapshot_name))
        else
          puts "#{ui.color("Locating Image", :magenta)}"
          @image = Image.find(:name => locate_config_value(:image_name), :region => @dc.region)
          storage_options.merge(:mount_image_id => @image.id,
                                :profit_bricks_image_password => @password)
        end

        @hdd1 = Storage.create(storage_options)
        wait_for("#{ui.color("Creating Storage", :magenta)}") { @dc.provisioned? }
        if locate_config_value(:Podnix_snapshot_name)
          @snapshot.rollback(:storage_id => @hdd1.id)
          wait_for("#{ui.color("Applying Snapshot", :magenta)}") { @dc.provisioned? }
        end

        @server = @dc.create_server(:cores => Chef::Config[:knife][:Podnix_cpus] || 1,
                                  :ram => Chef::Config[:knife][:Podnix_memory] || 1024,
                                  :name => Chef::Config[:knife][:Podnix_server_name] || "Server",
                                  :internet_access => true)
        wait_for("#{ui.color("Creating Server", :magenta)}") { @dc.provisioned? }

        @hdd1.connect(:server_id => @server.id, :bus_type => 'VIRTIO')
        wait_for("#{ui.color("Connecting Storage", :magenta)}") { @dc.provisioned? }

        puts "#{ui.color("Done creating new Server", :green)}"

        wait_for("#{ui.color("Waiting for the Server to boot", :magenta)}") { @server.running? }

        @server = Server.find(:id => @server.id)
        wait_for(ui.color("Waiting for the Server to be accessible", :magenta)) { ssh_test(@server.ips)  }
      end

      def ssh_test(ip)
        begin
          timeout 2 do
            s = TCPSocket.new ip, 22
            s.close
            true
          end
        rescue Timeout::Error, Errno::ECONNREFUSED
          false
        end
      end

      def upload_ssh_key
        ## SSH Key
        ssh_key = begin
          File.open(locate_config_value(:public_key_file)).read.gsub(/\n/,'')
        rescue Exception => e
          ui.error(e.message)
          ui.error("Could not read the provided public ssh key, check the public_key_file config.")
          exit 1
        end

        dot_ssh_path = if locate_config_value(:ssh_user) != 'root'
          ssh("useradd #{locate_config_value(:ssh_user)} -G sudo -m").run
          "/home/#{locate_config_value(:ssh_user)}/.ssh"
        else
          "/root/.ssh"
        end
        ssh("mkdir -p #{dot_ssh_path} && echo \"#{ssh_key}\" > #{dot_ssh_path}/authorized_keys && chmod -R go-rwx #{dot_ssh_path}").run
        puts ui.color("Added the ssh key to the authorized_keys of #{locate_config_value(:ssh_user)}", :green)
      end

      def change_password
        Net::SSH.start( @server.ips, 'root', :password =>@password, :paranoid => false ) do |ssh|
          ssh.open_channel do |channel|
             channel.on_request "exit-status" do |channel, data|
                $exit_status = data.read_long
             end
             channel.on_data do |channel, data|
                if data.inspect.include? "current"
                        channel.send_data("#{@password}\n");
                elsif data.inspect.include? "New"
                        channel.send_data("#{@new_password}\n");
                elsif data.inspect.include? "new"
                        channel.send_data("#{@new_password}\n");
                end
             end
             channel.request_pty
             channel.exec("passwd");
             channel.wait

             return $exit_status == 0
          end
        end
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
