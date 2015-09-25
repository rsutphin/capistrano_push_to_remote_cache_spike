# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "precise64"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", ip: "192.168.36.36"

  config.vm.provision "shell", inline: <<-SHELL
    sudo iptables -P OUTPUT ACCEPT && sudo iptables -F OUTPUT
    sudo apt-get update
    sudo apt-get install -y git-core
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent

    # Prevent outbound connections to prove that cloning is happening via SSH tunnel
    sudo iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
    sudo iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
    sudo iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
    sudo iptables -A OUTPUT -p tcp -d 127.0.0.1 -j ACCEPT
    sudo iptables -A OUTPUT -p tcp -d 10.0.2.0/24 -j ACCEPT
    sudo iptables -P OUTPUT DROP
    sudo iptables-save > /tmp/rules.v4
    sudo mv /tmp/rules.v4 /etc/iptables/rules.v4
  SHELL
end
