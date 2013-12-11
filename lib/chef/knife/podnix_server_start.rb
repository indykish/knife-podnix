require 'chef/knife'
require 'chef/json_compat'

require_relative 'podnix_base'
class Chef
  class Knife
    class PodnixServerStart < Knife
      require_relative 'podnix_base'
      deps do
        require 'podnix'
        require 'highline'        
        Chef::Knife.load_deps
      end

      include Chef::Knife::PodnixBase

      banner "knife podnix server start SERVER_ID OPTIONS"

      option :podnix_api_key,
        :short => "-K PODNIX_API_KEY",
        :long => "--podnix_api_key PODNIX_API_KEY",
        :description => "Podnix API key",
        :default => Chef::Config[:knife][:podnix_api_key]

      def run
      @server_id = @name_args[0]
        if @server_id.nil?
          ui.error("You must specify a server_id")
          exit 1        
       else
       
        validate!
        @podnix = Podnix::API.new({:key => "#{config[:podnix_api_key]}"})
        po_server = @podnix.start_server({:id => "#{@server_id}"})
      end
      end
    end
  end
end
