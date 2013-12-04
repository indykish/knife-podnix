require File.expand_path('../../spec_helper', __FILE__)

Chef::Knife::PodnixServerList.load_deps

describe Chef::Knife::PodnixServerList do
  before do
    {
      :Podnix_user => 'test',
      :Podnix_password => 'test',
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end
    @server_list = Chef::Knife::PodnixServerList.new
    @server = Podnix::Server.new(server_id: 'one', server_name: 'test', cores: 1, ram: 256)
    @Podnix = mock(Podnix::Server)
  end

  it "should display all images" do
    @dc = mock(Podnix::DataCenter)
    @dc.should_receive(:servers).and_return [@server]
    @dc.should_receive(:name).and_return "test"
    Podnix::DataCenter.should_receive(:all).and_return [@dc]
    @server_list.ui.should_receive(:list).and_return ""
    @server_list.run
  end
end