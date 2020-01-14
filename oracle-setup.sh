#!/bin/bash
#######################################################################################
#
# oracle-setup.sh
#
# Scripts to configure Fedora 31 for Oracle
#
# Source: https://oracle-base.com/articles/19c/oracle-db-19c-installation-on-fedora-31
#
# sudo bash -c "bash <(wget -qO- https://raw.githubusercontent.com/jmaaks/scripts/master/oracle-setup.sh)"
#######################################################################################

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi

# Set required kernel parameters
cat > /etc/sysctl.d/98-oracle.conf <<EOF
fs.file-max = 6815744
kernel.sem = 250 32000 100 128
kernel.shmmni = 4096
kernel.shmall = 1073741824
kernel.shmmax = 4398046511104
kernel.panic_on_oops = 1
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
fs.aio-max-nr = 1048576
net.ipv4.ip_local_port_range = 9000 65500
EOF

/sbin/sysctl -p /etc/sysctl.d/98-oracle.conf

cat > /etc/security/limits.d/oracle-database-server-19c-preinstall.conf <<EOF
oracle   soft   nofile    1024
oracle   hard   nofile    65536
oracle   soft   nproc    16384
oracle   hard   nproc    16384
oracle   soft   stack    10240
oracle   hard   stack    32768
oracle   hard   memlock    134217728
oracle   soft   memlock    134217728
EOF

# Stop & disable the firewall (can restart it later)
# systemctl stop firewalld
# systemctl disable firewalld

# Set SELinux to permissive by editing the "/etc/selinux/config" file:
# SELINUX=permissive
# sudo nano /etc/selinux/config

# Install required packages
dnf install -y bc    
dnf install -y binutils
#yum install -y compat-libcap1
dnf install -y compat-libstdc++-33   # not found
#yum install -y dtrace-modules
#yum install -y dtrace-modules-headers
#yum install -y dtrace-modules-provider-headers
#yum install -y dtrace-utils
dnf install -y elfutils-libelf
dnf install -y elfutils-libelf-devel
dnf install -y fontconfig-devel
dnf install -y glibc
dnf install -y glibc-devel
dnf install -y ksh
dnf install -y libaio
dnf install -y libaio-devel
#yum install -y libdtrace-ctf-devel
dnf install -y libXrender
dnf install -y libXrender-devel
dnf install -y libX11
dnf install -y libXau
dnf install -y libXi
dnf install -y libXtst
dnf install -y libgcc
dnf install -y librdmacm-devel
dnf install -y libstdc++
dnf install -y libstdc++-devel
dnf install -y libxcb
dnf install -y make
dnf install -y net-tools # Clusterware
dnf install -y nfs-utils # ACFS
dnf install -y python # ACFS
dnf install -y python-configshell # ACFS
dnf install -y python-rtslib # ACFS     # not found
dnf install -y python-six # ACFS
dnf install -y targetcli # ACFS
dnf install -y smartmontools
dnf install -y sysstat

# Added by me.
dnf install -y unixODBC

# New for F31
dnf install -y libnsl2
dnf install -y libnsl2.i686
dnf install -y libxcrypt-compat

dnf install -y http://rpmfind.net/linux/fedora/linux/development/rawhide/Everything/x86_64/os/Packages/c/compat-libpthread-nonshared-2.30.9000-18.fc32.x86_64.rpm

# Create required users and groups
groupadd -g 54321 oinstall
groupadd -g 54322 dba
groupadd -g 54323 oper
#groupadd -g 54324 backupdba
#groupadd -g 54325 dgdba
#groupadd -g 54326 kmdba
#groupadd -g 54328 asmdba
#groupadd -g 54328 asmoper
#groupadd -g 54329 asmadmin

useradd -u 54321 -g oinstall -G dba,oper oracle
passwd oracle

# Create the directories in which the Oracle software will be installed.

mkdir -p /u01/app/oracle/product/19.0.0/dbhome_1
mkdir -p /u02/oradata
chown -R oracle:oinstall /u01 /u02
chmod -R 775 /u01 /u02

# Edit the "/etc/redhat-release" file replacing the current release information "Fedora release 31 (Thirty One)" with the following.

# redhat release 7

# Fix for Oracle on F31.
rm -f /usr/lib64/libnsl.so.1
rm -f /usr/lib/libnsl.so.1
ln -s /usr/lib64/libnsl.so.2.0.0 /usr/lib64/libnsl.so.1
ln -s /usr/lib/libnsl.so.2.0.0 /usr/lib/libnsl.so.1

# Set up the environment for the "oracle" user. 
mkdir -p /home/oracle/scripts

cat > /home/oracle/scripts/setEnv.sh <<EOF
# Oracle Settings
export TMP=/tmp
export TMPDIR=\$TMP

export ORACLE_HOSTNAME=fedora31.localdomain
export ORACLE_UNQNAME=cdb1
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=\$ORACLE_BASE/product/19.0.0/dbhome_1
export ORA_INVENTORY=/u01/app/oraInvenotry
export ORACLE_SID=cdb1
export PDB_NAME=pdb1
export DATA_DIR=/u02/data

export PATH=/usr/sbin:/usr/local/bin:\$PATH
export PATH=\$ORACLE_HOME/bin:\$PATH

export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=\$ORACLE_HOME/jlib:\$ORACLE_HOME/rdbms/jlib
EOF

echo ". /home/oracle/scripts/setEnv.sh" >> /home/oracle/.bash_profile

chown -R oracle:oinstall /home/oracle/scripts
