# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.hostname = "go-to-live"
  config.vm.network "forwarded_port", guest: 8888, host: 8888
  # config.vm.box_check_update = false

  # pass-through salt configs into VM
  config.vm.synced_folder "salt/srv/", "/srv/salt"

  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.memory = "2048"
    vb.name = "go-to-live"
  end

  config.vm.provision :salt do |salt|
    salt.masterless = true
    salt.minion_config = "salt/minion"
    salt.run_highstate = true
    # buggy ubuntu salt needs to be updated
    # this is the only working approach I've found
    salt.bootstrap_script = "salt/bootstrap-salt.sh"
    salt.install_type = "git"
    salt.install_args = "v2016.3.0"
  end
end
