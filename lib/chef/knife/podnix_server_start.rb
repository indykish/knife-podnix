require 'chef/knife'
require 'chef/json_compat'

require_relative 'podnix_base'
class Chef
  class Knife
    class PodnixServerList < Knife
      require_relative 'podnix_base'
      deps do
        require 'podnix'
        require 'highline'        
        Chef::Knife.load_deps
      end

      include Chef::Knife::PodnixBase

      banner "knife podnix server start SERVER_NAME OPTIONS"

      option :podnix_api_key,
        :short => "-K PODNIX_API_KEY",
        :long => "--podnix_api_key PODNIX_API_KEY",
        :description => "Podnix API key",
        :default => Chef::Config[:knife][:podnix_api_key]

      def run
        validate!
        @podnix = Podnix::API.new({:key => "#{config[:podnix_api_key]}"})
        po_servers = @podnix.get_servers

        image_list = [
            ui.color('ID', :bold),
            ui.color('Name', :bold)]


        po_images.data[:body]['data'].each do |im|
          image_list << im['id']
          image_list << im['name']
        end

        puts ui.list(image_list, :uneven_columns_across, 2)
      end
    end
  end
end
