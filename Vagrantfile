# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.define :central_server do |central_server|

    central_server.vm.box = "UbuntuServer14.04-bento"
    central_server.vm.box_url = "https://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-14.04_chef-provisionerless.box"
    central_server.vm.network  :private_network, ip: "192.168.78.29"
    central_server.vm.host_name = "portal-udes-bioinfo"
#    central_server.vbguest.auto_update = false

    central_server.vm.provision :ansible do |ansible|
      ansible.inventory_path = "./ansible/host-vagrant"
      ansible.playbook = "./ansible/setup.yml"
      ansible.host_key_checking = false
      ansible.limit='all'
      ansible.verbose = "-vvvv"
    end
  end

end
