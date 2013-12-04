require File.expand_path('../../spec_helper', __FILE__)

require 'chef/knife/ssh'
describe Chef::Knife::PodnixBase do
  before do
    {
      :Podnix_user => 'test',
      :Podnix_password => 'test',
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end
    @base = Chef::Knife::PodnixImageList.new
  end

  it "should return the username" do
    @base.Podnix_user.should == 'test'
  end

  it "should return the password" do
    @base.Podnix_password.should == 'test'
  end

  it "should display error messages without a username or password" do
    @base.should_receive(:Podnix_user).and_return nil
    @base.ui.should_receive(:error).exactly(3).times
    lambda { @base.validate! }.should raise_error SystemExit
  end

  it "should configure the Podnix gem" do
    Podnix.should_receive(:configure)
    @base.configure
  end

  it "should print a message pair" do
    @base.ui.should_receive(:color).and_return "beautiful"
    @base.ui.should_receive(:info).with("beautiful: 123")
    @base.msg_pair('test', 123)
  end

  it "should wait for a block to return true" do
    @base.should_receive(:print).exactly(3).times
    i = 0
    @base.wait_for 'test' do
      i += 1
      i == 1 ? false : true
    end
  end

  it "should configure the ssh connection" do
    server = Podnix::Server.new(:ips => "1.1.1.1")
    @base.instance_variable_set(:@server, server)
    ssh = @base.ssh "ps"
    ssh.config.should == { :ssh_user=>"root", :ssh_password=>nil, :ssh_port=>22, :identity_file=>nil,
                           :manual=>true, :host_key_verify=>false, :on_error=>:raise }
  end
end