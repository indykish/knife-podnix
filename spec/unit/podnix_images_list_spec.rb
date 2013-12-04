require File.expand_path('../../spec_helper', __FILE__)

Chef::Knife::PodnixImageList.load_deps

describe Chef::Knife::PodnixImageList do
  before do
    {
      :Podnix_user => 'test',
      :Podnix_password => 'test',
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end
    @image_list = Chef::Knife::PodnixImageList.new
    @image = Podnix::Image.new(image_id: 'one', image_name: 'test', image_type: 'HDD', memory_hotpluggable: true, cpu_hotpluggable: true, size: 10, region: 'EUROPE')
    @Podnix = mock(Podnix::Image)
  end

  it "should display all images" do
    Podnix::Image.should_receive(:all).and_return [@image]
    @image_list.ui.should_receive(:list).and_return ""
    @image_list.run
  end
end