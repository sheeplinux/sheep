# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV["LC_ALL"] = "en_US.UTF-8"

Vagrant.configure(2) do |config|

    config.vm.box = "ubuntu/xenial64"
    config.vm.hostname = 'sheep'

    config.vm.provider 'virtualbox' do |vb|
        vb.customize ['modifyvm', :id, '--memory', '1024']
        vb.customize ['modifyvm', :id, '--chipset', 'ich9']
    end

    config.vm.provision "shell", privileged: false, inline: <<-SHELL
        set -ex

        #
        # Install yq
        #
        sudo apt update
        sudo apt install -y python-pip jq
        sudo pip install yq

        #
        # Install bats
        #
        git clone https://github.com/sstephenson/bats.git
        cd bats
        sudo ./install.sh /usr/local
        cd ..
        rm -rf bats
    SHELL

end
