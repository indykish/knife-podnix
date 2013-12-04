require File.expand_path('../../spec_helper', __FILE__)

Chef::Knife::PodnixServerCreate.load_deps
require 'chef/knife/ssh'

describe Chef::Knife::PodnixServerCreate do
  before do
    {
      :Podnix_user => 'test',
      :Podnix_password => 'test',
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end
    @server_create = Chef::Knife::PodnixServerCreate.new
    @server = Podnix::Server.new(server_id: 'one', server_name: 'test', cores: 1, ram: 256)
    @Podnix = mock(Podnix::Server)
    @server = Podnix::Server.new(:ips => "0.0.0.0")
    @server_create.instance_variable_set(:@server, @server)
  end

  it "should return an HighLine instance" do
    @server_create.h.class.should == HighLine
  end

  it "should run bootstrap" do
    @bootstrap = Chef::Knife::Bootstrap.new
    Chef::Knife::Bootstrap.stub!(:new).and_return(@bootstrap)
    @bootstrap.should_receive(:run)

    ssh = Chef::Knife::Ssh.new
    Chef::Knife::Ssh.stub(:new).and_return(ssh)
    ssh.should_receive(:run)

    @server_create.bootstrap
  end

  it "should test the ssh connectivity and fail" do
    TCPSocket.should_receive(:new).and_raise(Errno::ECONNREFUSED)
    @server_create.ssh_test("0.0.0.0").should == false
  end

  it "should successfully test the ssh connectivity" do
    socket = mock()
    socket.should_receive(:close)
    TCPSocket.should_receive(:new).and_return(socket)
    @server_create.ssh_test("0.0.0.0").should == true
  end

  it "should fail to upload the ssh key" do
    @server_create.ui.should_receive(:error).exactly(2).times
    lambda { @server_create.upload_ssh_key }.should raise_error SystemExit
  end

  it "should upload the ssh key correctly" do
    Chef::Config[:knife][:ssh_user] = 'test'
    file = mock()
    file.should_receive(:read).and_return("sshkey")
    File.stub(:open).and_return(file)

    ssh = Chef::Knife::Ssh.new
    @server_create.should_receive(:ssh).once.ordered.with("useradd test -G sudo -m").and_return(ssh)
    @server_create.should_receive(:ssh).once.ordered.with("mkdir -p /home/test/.ssh && echo \"sshkey\" > /home/test/.ssh/authorized_keys && chmod -R go-rwx /home/test/.ssh").and_return(ssh)
    ssh.should_receive(:run).twice
    @server_create.stub(:puts)

    @server_create.upload_ssh_key
  end

  it "should upload the ssh key correctly when the ssh_user is root" do
    Chef::Config[:knife][:ssh_user] = 'root'
    file = mock()
    file.should_receive(:read).and_return("sshkey")
    File.stub(:open).and_return(file)

    ssh = Chef::Knife::Ssh.new
    @server_create.should_receive(:ssh).once.ordered.with("mkdir -p /root/.ssh && echo \"sshkey\" > /root/.ssh/authorized_keys && chmod -R go-rwx /root/.ssh").and_return(ssh)
    ssh.should_receive(:run).once
    @server_create.stub(:puts)

    @server_create.upload_ssh_key
  end

  it "should not run without a datacenter name" do
    @server_create.ui.should_receive(:error).with("A Datacenter must be specified")
    lambda { @server_create.run }.should raise_error SystemExit
  end

  it "should not run without a datacenter name" do
    Chef::Config[:knife][:Podnix_datacenter] = 'test'
    @server_create.ui.should_receive(:error).with("You need to provide a name for the server")
    lambda { @server_create.run }.should raise_error SystemExit
  end

  it "should run correctly" do
    Chef::Config[:knife][:Podnix_datacenter] = 'test'
    Chef::Config[:knife][:Podnix_server_name] = 'test'
    @server_create.stub(:config).and_return({:bootstrap => true})
    @server_create.stub(:msg_pair)
    @server_create.stub(:puts)
    @server_create.ui.stub(:info)
    dc = mock()
    dc.should_receive(:name).and_return("dc")
    dc.should_receive(:wait_for_provisioning)
    Podnix::DataCenter.stub(:find).and_return(dc)
    @server_create.should_receive(:create_server)
    @server_create.should_receive(:change_password)
    @server_create.should_receive(:upload_ssh_key)
    @server_create.should_receive(:bootstrap)

    @server_create.run
  end

  it "should create a server" do
    @server_create.stub(:msg_pair)
    @server_create.stub(:puts)
    @server_create.stub(:print)
    server = Podnix::Server.new
    server.should_receive(:running?).and_return(true)

    dc = Podnix::DataCenter.new(:id => '1234', :region => 'EUROPE')
    dc.stub(:provisioned?).and_return(true)
    dc.should_receive(:create_server).and_return(server)
    @server_create.instance_variable_set(:@dc, dc)

    image = Podnix::Image.new(:id => '1234')
    hdd = Podnix::Storage.new(:id => '1234')
    hdd.should_receive(:connect)

    Podnix::Image.should_receive(:find).and_return(image)
    Podnix::Storage.should_receive(:create).and_return(hdd)
    Podnix::Server.should_receive(:find).and_return(server)

    @server_create.create_server
  end

  it "should change the default password" do
    @server_create.instance_variable_set(:@password, "test")
    ssh = mock("SSH")
    data = mock("data")
    data.should_receive(:read_long).and_return(0)
    channel = mock("channel")
    channel.stub(:on_request).and_yield(channel, data)
    channel.should_receive(:on_data).and_yield(channel, "current")
    channel.should_receive(:send_data).with("test\n")
    channel.should_receive(:request_pty)
    channel.should_receive(:exec).with("passwd")
    channel.should_receive(:wait)
    ssh.should_receive(:open_channel).and_yield(channel)
    Net::SSH.should_receive(:start).and_yield(ssh)
    @server_create.change_password.should == true
  end
end