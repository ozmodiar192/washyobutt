#!/bin/bash
# This script assumes an Ubuntu 16.04 system or later

#Set script variables
vagrantDir=~/vagrant
cwDir="$( cd "$( dirname "$0" )" && pwd )"


#Check for an existing vagrantfile and exit if found
if [ -f ${vagrantDir}/Vagrantfile ]; then
  printf "It looks like there's already a Vagrant configuration at ${vagrantDir}.\nExiting so you can figure this out.\n"
  exit 1
fi

#Update everything and install virtualbox and vagrant
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install virtualbox
sudo apt-get -y install vagrant

#Store all vagrant files in vagrantdir instead of .
if [ ! -d ${vagrantDir} ]; then 
  mkdir -p ${vagrantDir}
fi 

# Initialize the box and copy in our vagrant template.
export VAGRANT_CWD=${vagrantDir}
vagrant init ubuntu/xenial64
cp ./Vagrantfile.template ${VAGRANT_CWD}/Vagrantfile
cp ./provision.sh ${VAGRANT_CWD}/provision.sh
# Update the vagrantfile to mount the wyb project dir
sed -i "s|wybDir|${cwDir}/..|g" ~/vagrant/Vagrantfile

#Put vagrant_cwd into .bash_profile
if [ ! -f ~/.bash_profile ]; then
  touch ~/.bash_profile
fi
if ! grep -xq "export VAGRANT_CWD=${VAGRANT_CWD}" ~/.bash_profile; then
  echo "export VAGRANT_CWD=${VAGRANT_CWD}" >> ~/.bash_profile
  printf "\n\n########        HEY YOU       ########\n#            Please execute:         #\n#  source ~/.bash_profile            #\n#            before executing:       #\n#  vagrant up                        #\n######################################\n\n" 
else
  vagrant up
fi
