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
wget -O -  https://get.acme.sh | sh -s email=certs@swstack.com
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
sed -i '/\[realms\]/d' /etc/krb5.conf
sed -i '/\[domain_realm\]/d' /etc/krb5.conf
cat << EOF >> /etc/krb5.conf
[realms]
   SWSTACK.COM = {
      kdc = kdc.swstack.com
      admin_server = kdc.swstack.com
     }
[domain_realm]
  .swstack.com = SWSTACK.COM
EOF

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

cat << EOF >> /etc/keystone/domains/keystone.mycloud.conf
[identity]
driver = ldap

[ldap]
url=ldap://ldap.swstack.com
suffix=dc=swstack,dc=com
user_tree_dn=ou=kcloud,dc=swstack,dc=com
user_objectclass=organizationalPerson
user_id_attribute=uid
user_name_attribute=uid
#user_mail_attribute=mail
#user_enabled_attribute=nsAccountLock
#user_enabled_default=False
#user_enabled_invert=true
systemctl restart httpd
EOF
```
### Make Changes in /etc/keystone/keystone.conf
```
[auth]
methods = external,password,token,kerberos,oauth1,mapped,application_credential
[federation]
federated_domain_name = mycloud
[identity]
domain_specific_drivers_enabled = true
domain_config_dir = /etc/keystone/domains
```
### Enable Multi Domain Support in OpenStack Keystone
```
sed -i 's/^OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT \=.*/OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT \=y/' /etc/openstack-dashboard/local_settings
```
### Configure authenticated email relay [TODO]
```
sed -i <following params> /etc/openstack-dashboard/local_settings
# Configure these for your outgoing email host
#EMAIL_HOST = 'smtp.my-company.com'
#EMAIL_PORT = 25
#EMAIL_HOST_USER = 'djangomail'
#EMAIL_HOST_PASSWORD = 'top-secret!'
```

### 
