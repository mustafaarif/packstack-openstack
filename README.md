# Deployment guide for OpenStack with PackStack
This guide is for deploying OpenStack with PackStack. It also then configures OpenLdap authentication with Kerberos. 

## Setup Host Centos Stream 9 or Rocky Linux 9

Ideally the VM or Host should have 8 vCPUs and 16GB Memory.
Issue below to install required packages and perform preconfiguration tasks.

```
./setup_host.sh
```

## Generate and Setup SSL Certificates (Optional)

```
export HOST_NAME="cloud.swstack.com"
dnf -y install socat
wget -O -  https://get.acme.sh | sh -s email=certs@emarif.com
# Make sure 443/80 ports are open
~/.acme.sh/acme.sh --issue  -d ${HOST_NAME}  --standalone
cp /root/.acme.sh/${HOST_NAME}_ecc/cloud.swstack.com.key /etc/ssl/certs
cp /root/.acme.sh/${HOST_NAME}_ecc/cloud.swstack.com.cer /etc/ssl/certs
cp /root/.acme.sh/${HOST_NAME}_ecc/ca.cer /etc/ssl/certs
```

## Setup answer file for PackStack
```
packstack --gen-answer-file=answers.txt

# Modify answer file to suit our needs
DEFAULT_PASS=`openssl rand -base64 32`
ADMIN_PASS="admin_osdev2023"
DEMO_PASS="demo_osdev2023"
sed -i 's/^CONFIG_DEFAULT_PASSWORD\=.*/CONFIG_DEFAULT_PASSWORD\='${DEFAULT_PASS}'/' answers.txt
sed -i 's/^CONFIG_MAGNUM_INSTALL\=.*/CONFIG_MAGNUM_INSTALL\=y/' answers.txt
sed -i 's/^CONFIG_KEYSTONE_ADMIN_PW\=.*/CONFIG_KEYSTONE_ADMIN_PW\='${ADMIN_PASS}'/' answers.txt
sed -i 's/^CONFIG_KEYSTONE_DEMO_PW\=.*/CONFIG_KEYSTONE_DEMO_PW\='${DEMO_PASS}'/' answers.txt
sed -i 's/^CONFIG_HORIZON_SSL\=.*/CONFIG_HORIZON_SSL\=y/' answers.txt
sed -i 's/^CONFIG_KEYSTONE_ADMIN_EMAIL\=.*/CONFIG_KEYSTONE_ADMIN_EMAIL\=cloudadmin@swstack.com/' answers.txt
sed -i 's/^CONFIG_HORIZON_SSL_CERT\=.*/CONFIG_HORIZON_SSL_CERT\=\/etc\/ssl\/certs\/cloud\.swstack\.com\.key/' answers.txt
sed -i 's/^CONFIG_HORIZON_SSL_KEY\=.*/CONFIG_HORIZON_SSL_KEY\=\/etc\/ssl\/certs\/cloud\.swstack\.com\.key/' answers.txt
sed -i 's/^CONFIG_HORIZON_SSL_CACERT\=.*/CONFIG_HORIZON_SSL_CACERT\=\/etc\/ssl\/certs\/ca\.cer/' answers.txt
# Verify
grep -a 'CONFIG_MAGNUM_INSTALL\|CONFIG_DEFAULT_PASSWORD\|CONFIG_KEYSTONE_ADMIN_PW\|CONFIG_KEYSTONE_DEMO_PW\|CONFIG_HORIZON_SSL\|CONFIG_KEYSTONE_ADMIN_EMAIL\|CONFIG_HORIZON_SSL_CERT\|CONFIG_HORIZON_SSL_KEY\|CONFIG_HORIZON_SSL_CACERT' answers.txt
```

## Install OpenStack
```
packstack --answer-file answers.txt

```
## Setup Kerberos on host
```
cp krb5.conf /etc/
## Test
kinit clouduser1@SWSTACK.COM
```
## Install Python Packages for Kerberos
```
pip install keystoneauth1[kerberos]
```
## Integrate OpenStack with LDAP via a Domain
### Create a Domain file
```
mkdir -p /etc/keystone/domains
touch /etc/keystone/domains/keystone.mycloud.conf
systemctl restart httpd
```
### Make Changes in /etc/keystone.conf
```
```
