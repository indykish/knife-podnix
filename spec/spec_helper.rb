$:.unshift File.expand_path('../../lib', __FILE__)



require 'chef'
require 'podnix'
require 'chef/knife/Podnix_base'
require 'chef/knife/Podnix_images_list'
require 'chef/knife/Podnix_server_create'
require 'chef/knife/Podnix_server_list'
require 'chef/knife/Podnix_server_delete'