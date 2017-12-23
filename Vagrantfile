# -*- mode: ruby -*-
# vi: set ft=ruby ts=2 sw=2 et:

# Adapted from github.com/Varying-Vagrant-Vagrants/VVV
# See there as a reference for what else is possible
# e.g. implementing a config file

working_dir = File.expand_path(File.dirname(__FILE__))

# configuration, could be extended to use config file
local_config = Hash.new
local_config['hosts'] = Array.new
local_config['vm_config'] = Hash.new
local_config['vm_config']['memory'] = 1024
local_config['vm_config']['cores'] = 1

# searches for host entries from sites dir
def map_hosts(name)
  var = name == "default" ? "local.dev" : name + ".local.dev"
  return var
end

local_config['hosts'] += Dir[File.join(working_dir, 'config', 'nginx-config', 'sites', '*')]
.map! {|f| map_hosts(f.split('/')[-1])}

Vagrant.configure("2") do |config|

  # Store the current version of Vagrant for use in conditionals when dealing
  # with possible backward compatible issues.
  vagrant_version = Vagrant::VERSION.sub(/^v/, '')

  # Configurations from 1.0.x can be placed in Vagrant 1.1.x specs like the following.
  config.vm.provider :virtualbox do |v|
    v.customize ["modifyvm", :id, "--memory", local_config['vm_config']['memory']]
    v.customize ["modifyvm", :id, "--cpus", local_config['vm_config']['cores']]
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    v.customize ["modifyvm", :id, "--natdnsproxy1", "on"]

    # Set the box name in VirtualBox to match the working directory.
    pwd = Dir.pwd
    v.name = File.basename(pwd)
  end

  # Configuration options for the Parallels provider.
  config.vm.provider :parallels do |v|
    v.update_guest_tools = true
    v.customize ["set", :id, "--longer-battery-life", "off"]
    v.memory = local_config['vm_config']['memory']
    v.cpus = local_config['vm_config']['cores']
  end

  # Configuration options for the VMware Fusion provider.
  config.vm.provider :vmware_fusion do |v|
    v.vmx["memsize"] = local_config['vm_config']['memory']
    v.vmx["numvcpus"] = local_config['vm_config']['cores']
  end

  # Configuration options for Hyper-V provider.
  config.vm.provider :hyperv do |v, override|
    v.memory = local_config['vm_config']['memory']
    v.cpus = local_config['vm_config']['cores']
  end

  # SSH Agent Forwarding
  #
  # Enable agent forwarding on vagrant ssh commands. This allows you to use ssh keys
  # on your host machine inside the guest. See the manual for `ssh-add`.
  config.ssh.forward_agent = true

  # Default Centos Box
  # for VirtualBox
  # configure below if you need other providers
  config.vm.box = "bento/centos-7.3"

  # # The Parallels Provider uses a different naming scheme.
  config.vm.provider :parallels do |v, override|
    override.vm.box = "bento/centos-7.3"
  end

  # # The VMware Fusion Provider uses a different naming scheme.
  config.vm.provider :vmware_fusion do |v, override|
    override.vm.box = "bento/centos-7.3"
  end

  # # VMWare Workstation can use the same package as Fusion
  config.vm.provider :vmware_workstation do |v, override|
    override.vm.box = "bento/centos-7.3"
  end

  # # Hyper-V uses a different base box.
  config.vm.provider :hyperv do |v, override|
    override.vm.box = "bento/centos-7.3"
  end

  config.vm.hostname = "local"

  # Local Machine Hosts
  #
  # If the Vagrant plugin hostsupdater (https://github.com/cogitatio/vagrant-hostsupdater) is
  # installed, the following will automatically configure your local machine's hosts file to
  # be aware of the domains specified below. Watch the provisioning script as you may need to
  # enter a password for Vagrant to access your hosts file.
  #
  # By default, we'll include the domains set up through the hosts file
  # located in the config/ directory.
  if defined?(VagrantPlugins::HostsUpdater)

    # Pass the found host names to the hostsupdater plugin so it can perform magic.
    config.hostsupdater.aliases = local_config['hosts']
    config.hostsupdater.remove_on_suspend = true
  end

  # Private Network (default)
  #
  # A private network is created by default. This is the IP address through which your
  # host machine will communicate to the guest. In this default configuration, the virtual
  # machine will have an IP address of 192.168.60.4 and a virtual network adapter will be
  # created on your host machine with the IP of 192.168.60.1 as a gateway.
  #
  # Access to the guest machine is only available to your local host. To provide access to
  # other devices, a public network should be configured or port forwarding enabled.
  #
  # Note: If your existing network is using the 192.168.50.x subnet, this default IP address
  # should be changed. If more than one VM is running through VirtualBox, including other
  # Vagrant machines, different subnets should be used for each.
  #
  config.vm.network :private_network, id: "local_primary", ip: "192.168.60.4"

  config.vm.provider :hyperv do |v, override|
    override.vm.network :private_network, id: "local_primary", ip: nil
  end

  # Port Forwarding (disabled)
  #
  # This network configuration works alongside any other network configuration in Vagrantfile
  # and forwards any requests to port 8080 on the local host machine to port 80 in the guest.
  #
  # Port forwarding is a first step to allowing access to outside networks, though additional
  # configuration will likely be necessary on our host machine or router so that outside
  # requests will be forwarded from 80 -> 8080 -> 80.
  #
  # Please see VVV and Vagrant documentation for additional details.
  #
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Drive mapping
  #
  # The following config.vm.synced_folder settings will map directories in your Vagrant
  # virtual machine to directories on your local machine. Once these are mapped, any
  # changes made to the files in these directories will affect both the local and virtual
  # machine versions. Think of it as two different ways to access the same file. When the
  # virtual machine is destroyed with `vagrant destroy`, your files will remain in your local
  # environment.

  # /srv/config/
  #
  # If a server-conf directory exists in the same directory as your Vagrantfile,
  # a mapped directory inside the VM will be created that contains these files.
  # This directory is currently used to maintain various config files for php and
  # nginx as well as any pre-existing database files.
  config.vm.synced_folder "config/", "/srv/config"

  # /var/log/
  #
  # If a log directory exists in the same directory as your Vagrantfile, a mapped
  # directory inside the VM will be created for some generated log files.
  config.vm.synced_folder "log/", "/var/log", :mount_options => [ "dmode=777", "fmode=777" ]

  # /var/www/
  #
  # If a www directory exists in the same directory as your Vagrantfile, a mapped directory
  # inside the VM will be created that acts as the default location for nginx sites. Put all
  # of your project files here that you want to access through the web server
  config.vm.synced_folder "www/", "/var/www/", :owner => "5000", :mount_options => [ "dmode=775", "fmode=774" ]

  # The Parallels Provider does not understand "dmode"/"fmode" in the "mount_options" as
  # those are specific to Virtualbox. The folder is therefore overridden with one that
  # uses corresponding Parallels mount options.
  config.vm.provider :parallels do |v, override|
    override.vm.synced_folder "www/", "/var/www/", :owner => "5000", :mount_options => []
  end

  # The Hyper-V Provider does not understand "dmode"/"fmode" in the "mount_options" as
  # those are specific to Virtualbox. Furthermore, the normal shared folders need to be
  # replaced with SMB shares. Here we switch all the shared folders to us SMB and then
  # override the www folder with options that make it Hyper-V compatible.
  config.vm.provider :hyperv do |v, override|
    override.vm.synced_folder "www/", "/var/www/", :owner => "5000", :mount_options => ["dir_mode=0775","file_mode=0774","forceuid","noperm","nobrl","mfsymlinks"]
    # Change all the folder to use SMB instead of Virtual Box shares
    override.vm.synced_folders.each do |id, options|
      if ! options[:type]
        options[:type] = "smb"
      end
    end
  end

  # Provisioning
  # provision.sh
  #
  # Vagrantfile is set to use the provision.sh bash script located in the
  # provision directory.
  config.vm.provision "default", type: "shell", path: File.join( "provision", "provision.sh" )

  # (run: "always" support added in 1.6.0)
  config.vm.provision "shell", run: "always" do |s|
    s.inline = <<-SHELL
      echo "Restart services"
      sudo systemctl restart php-fpm
      sudo systemctl restart mariadb
      sudo bash /srv/config/reload-nginx.sh
    SHELL
  end
end
