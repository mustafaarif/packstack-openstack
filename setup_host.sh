#!/bin/bash

echo "$0: Updating host system..."
dnf -y update
echo "$0: Installing required packages..."
dnf -y install vim tmux dnsutils krb5-workstation.x86_64 mod_auth_gssapi.x86_64 python3-requests-gssapi.noarch python3-gssapi.x86_64 cyrus-sasl-gssapi.x86_64 krb5-devel
echo "$0: Enabling crb repo..."
dnf config-manager --enable crb
echo "$0: Installing OpenStack Yoga..."
dnf install -y centos-release-openstack-yoga
dnf -y update
echo "$0: Installing Packstack..."
dnf install -y openstack-packstack
echo "$0: Disabling SeLinux..."
setenforce 0
sed -i 's/SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
echo "$0: Setting up network..."
dnf install -y network-scripts
systemctl disable NetworkManager
systemctl stop NetworkManager
/etc/rc.d/init.d/network start
chkconfig network on
chkconfig --add network
echo "$0: Setting up /etc/hosts file"
ipv4=`curl -4 ifconfig.me/ip`
echo "$ipv4 cloud.swstack.com" > /etc/hosts
echo "127.0.0.1 localhost.localdomain localhost" >> /etc/hosts
echo "$0: Done.."
