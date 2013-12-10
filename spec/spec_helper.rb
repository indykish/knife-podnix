$:.unshift File.expand_path('../../lib', __FILE__)



require 'chef'
require 'podnix'
require 'chef/knife/podnix_base'
require 'chef/knife/podnix_images_list'
require 'chef/knife/podnix_server_create'
require 'chef/knife/podnix_server_list'
require 'chef/knife/podnix_server_show'
require 'chef/knife/podnix_server_delete'
