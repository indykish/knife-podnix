require File.expand_path('../../spec_helper', __FILE__)

Chef::Knife::PodnixImageList.load_deps

describe Chef::Knife::PodnixImageList do
  before do
    {
      :podnix_user => 'test',
      :podnix_password => 'test',
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end
    
    SANDBOX_HOST_OPTIONS = {
      :scheme => 'https',
  :host => 'api.podnix.com',
      :nonblock => false,
   :port => 443
   
}
options ={}
s_options = SANDBOX_HOST_OPTIONS.merge({
  :api_key => ENV['PODNIX_API_KEY']  
}) 

  options = s_options.merge(options)
  opt={:api_key => ENV['PODNIX_API_KEY'] }
    @image_list = Chef::Knife::PodnixImageList.new
    #@image = Podnix::Image.new(image_id: 'one', image_name: 'test', image_type: 'HDD', memory_hotpluggable: true, cpu_hotpluggable: true, size: 10, region: 'EUROPE')
    @podnix = Podnix::API.new
    #@images = @podnix.get_images
    @images = @podnix.add_server({
:name => "tom.megam.co",
:model => "1",
:image => "37",
:password => "Team4megam",
:ssd => "1",
:storage => '10'
})
  end

  it "should display all images" do
  puts @images.inspect
    #Podnix::Image.should_receive(:all).and_return [@image]
    #@image_list.ui.should_receive(:list).and_return ""
    #@image_list.run
  end
end
