# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.define :vm-bio-info do |vm-bio-info|

    vm-bio-info.vm.box = "UbuntuServer14.04-bento"
    vm-bio-info.vm.box_url = "https://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-14.04_chef-provisionerless.box"
    vm-bio-info.vm.network  :private_network, ip: "192.168.78.29"
    vm-bio-info.vm.host_name = "portal-udes-bioinfo"
#    vm-bio-info.vbguest.auto_update = false

    vm-bio-info.vm.provision :ansible do |ansible|
      ansible.inventory_path = "./ansible/host-vagrant"
      ansible.playbook = "./ansible/setup.yml"
      ansible.host_key_checking = false
      ansible.limit='all'
      ansible.verbose = "-vvvv"
    end
  end

end
