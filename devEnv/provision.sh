#!/bin/bash

#Variables
## The hashicorp GPG signature fingerprint, obtained from https://www.hashicorp.com/security.html
hashiFingerprint="91A6E7F85D05C65630BEF18951852D87348FFC4C"
## The version of terraform we want to install
desiredTerraformVersion="0.11.7"

# Functions
# Downloads terraform files and verifys pgp keys
downloadTerraform(){
  wget https://releases.hashicorp.com/terraform/${desiredTerraformVersion}/terraform_${desiredTerraformVersion}_linux_amd64.zip
  wget https://releases.hashicorp.com/terraform/${desiredTerraformVersion}/terraform_${desiredTerraformVersion}_SHA256SUMS
  wget https://releases.hashicorp.com/terraform/${desiredTerraformVersion}/terraform_${desiredTerraformVersion}_SHA256SUMS.sig

  # Get the hashicorp key from pool.sks-keyservers.net
  gpg --keyserver pool.sks-keyservers.net --recv-key 51852D87348FFC4C

  # Check that the fingerprint of the gpg matches what's on the hashicorp site.
  fingerprint=`gpg --fingerprint 51852D87348FFC4C | grep "Key fingerprint" | cut -d"=" -f2 | sed 's/ //g'`
  if [ ${fingerprint} == ${hashiFingerprint} ]; then
    echo "Verified fingerprint of Hashicorp gpg key"
  else
    echo "Got a bad gpg signature"
    exit 1
  fi

   # Verify the list of terraform checksums against the signature. The download itself is not signed, only the sums.  Therefore, if the sums are correct, we can checksum the file and trust the download.
  if gpg --verify terraform_${desiredTerraformVersion}_SHA256SUMS.sig terraform_${desiredTerraformVersion}_SHA256SUMS; then
    echo "Verified the SHA256 Checksums"
  else
    echo "Could not verify Hashicorp GPG signature!"
    exit 1
  fi

   # Now that we know the sha sums file is correct, we can check the sum of the download against it.
   filesig=`shasum -a 256 terraform_${desiredTerraformVersion}_linux_amd64.zip`
  if grep ${filesig} terraform_${desiredTerraformVersion}_SHA256SUMS; then
    echo "Download verified"
  else
    echo "SHA signature on terraform download did not match!  Something is wrong."
    exit 1
  fi
}
    
sudo apt-get install -y zip
mkdir -p /home/vagrant/bin
if [ ! -f terraform_${desiredTerraformVersion}_linux_amd64.zip ]; then
  downloadTerraform
fi
unzip -o terraform_${desiredTerraformVersion}_linux_amd64.zip -d /home/vagrant/bin
echo "export PATH=${PATH}:/home/vagrant/bin" >> /home/vagrant/.bashrc

# Check if the user already has a private directory for sensitive files.
if [ ! -d /opt/wyb/private ]; then
  echo "Creating a private directory for sensitive files"
  echo "mkdir -p /opt/washyobutt/private"
else
  echo "private dir exists"
fi

#Look for a wyb deployer key
if [[ ! -f /opt/wyb/private/wyb_provisioner ]] && [[ ! -f /opt/wyb/private/wyb_provisioner.pub ]]; then
  echo "No provisioning key found"
  ssh-keygen -f /opt/wyb/private/wyb_provisioner -t rsa -b 4096 -C "wyb_provisioning" -q -N ""
  wybProvisionerPub=`cat /opt/wyb/private/wyb_provisioner.pub`
  if [ -f /opt/wyb/terraform/vpc_public/terraform.tfvars ]; then
    echo "appending new public key to your terraform.tfvars"
    echo "provisionerPublicKey = \"${wybProvisionerPub}\"" >> /opt/wyb/terraform/vpc_public/terraform.tfvars
  else
    touch /opt/wyb/terraform/vpc_public/terraform.tfvars
    echo "provisionerPublicKey = \"${wybProvisionerPub}\"" >> /opt/wyb/terraform/vpc_public/terraform.tfvars
  fi
fi
