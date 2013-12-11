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
         
      def locate_config_value(key)
        key = key.to_sym
        config[key] || Chef::Config[:knife][key]
      end

    end
  end
end
