#!/bin/bash
#
# Install a VLMCSD service for CentOS/RedHat
#

cd /etc/yum.repos.d/
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
yum update -y

check_result() {
  if [ $1 -ne 0 ]; then
    echo "Error: $2" >&2
    exit $1
  fi
}

if [ "x$(id -u)" != 'x0' ]; then
  echo 'Error: This script can only be executed by root'
  exit 1
fi

if [ -f '/etc/init.d/vlmcsd' ]; then
  echo 'VLMCSD service has been installed.'
  exit 1
fi

if [ ! -f '/sbin/service' ]; then
  echo 'Installing initscripts ...'
  yum -q -y install initscripts
  check_result $? "Can't install initscripts."
  echo 'Install initscripts succeed.'
fi

yum -q -y install wget tar net-tools

TMP_DIR=`mktemp -d`
GIT_TAG=svn1112
cd ${TMP_DIR}

echo 'Downloading vlmcsd ...'
wget -q https://github.com/Wind4/vlmcsd/releases/download/${GIT_TAG}/binaries.tar.gz -O binaries.tar.gz
check_result $? 'Download vlmcsd failed.'

echo 'Downloading startup script ...'
wget -q https://wind4.github.io/vlmcsd/scripts/init.d/vlmcsd-rhel -O vlmcsd.init
check_result $? 'Download startup script failed.'

echo 'Extract vlmcsd ...'
tar zxf binaries.tar.gz
cp binaries/Linux/intel/static/vlmcsd-x86-musl-static /usr/bin/vlmcsd
cp vlmcsd.init /etc/init.d/vlmcsd

echo 'Fix Permissions ...'
chmod 755 /usr/bin/vlmcsd
chown root.root /usr/bin/vlmcsd
chmod 755 /etc/init.d/vlmcsd
chown root.root /etc/init.d/vlmcsd

echo 'Configuring deamon ...'
chkconfig --add vlmcsd
chkconfig vlmcsd on
service vlmcsd start
check_result $? 'Installation failed.'

echo 'Cleaning ...'
rm -rf ${TMP_DIR}

echo 'Installed successfully.'
