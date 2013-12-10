require 'chef/knife'
require 'chef/json_compat'

require_relative 'podnix_base'
class Chef
  class Knife
    class PodnixServerShow < Knife
      require_relative 'podnix_base'
      deps do
        require 'podnix'
        require 'highline'        
        Chef::Knife.load_deps
      end

      include Chef::Knife::PodnixBase

      banner "knife podnix server show SERVER_ID OPTIONS"

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
        po_server = @podnix.get_server({:id => "#{@server_id}"})

        server_show = [
            ui.color('ID', :bold),
            ui.color('Name', :bold)]


        po_server.data[:body]['data'].each do |im|
          server_show << im['id']
          server_show << im['name']
        end

        puts ui.list(server_show, :uneven_columns_across, 2)
      end
      end
    end
  end
end
