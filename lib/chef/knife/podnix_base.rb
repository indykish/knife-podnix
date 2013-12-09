require 'chef/knife'

class Chef
  class Knife
    module PodnixBase

      def validate!
        if (!podnix_apikey)
          ui.error "You did not configure your podnix_api_key"
          ui.error "either export PODNIX_API_KEY in .bashrc"
          ui.error "or configure podnix_api_key in knife.rb"
          exit 1
        end
      end

      def msg_pair(label, value, color=:cyan)
        if value && !value.to_s.empty?
          ui.info "#{ui.color(label, color)}: #{value}"
        end
      end
      
      def podnix_apikey
        locate_config_value(:podnix_api_key) || ENV['PODNIX_API_KEY']
      end
      
      
      def wait_for msg, &block
        print msg
        while !block.call
          print '.'
          sleep 1
        end
        print "\n"
      end

      def ssh(command)
        ssh = Chef::Knife::Ssh.new
        ssh.ui = ui
        ssh.name_args = [ @server.ips, command ]
        ssh.config[:ssh_user] = "root"
        ssh.config[:ssh_password] = @password
        ssh.config[:ssh_port] = 22
        #ssh.config[:ssh_gateway] = Chef::Config[:knife][:ssh_gateway] || config[:ssh_gateway]
        ssh.config[:identity_file] = locate_config_value(:identity_file)
        ssh.config[:manual] = true
        ssh.config[:host_key_verify] = false
        ssh.config[:on_error] = :raise
        ssh
      end
      
      
      def locate_config_value(key)
        key = key.to_sym
        config[key] || Chef::Config[:knife][key]
      end

    end
  end
end
