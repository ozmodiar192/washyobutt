#!/bin/bash

#Variables
## The hashicorp GPG signature fingerprint, obtained from https://www.hashicorp.com/security.html
hashiFingerprint="91A6E7F85D05C65630BEF18951852D87348FFC4C"
## The ID of the HashiCorp public key, also from the site.
hashiPublicKeyId="51852D87348FFC4C"
## The version of terraform we want to install
desiredTerraformVersion="0.11.7"
## The location we want to install terraform
terraformBinDir="/home/vagrant/bin"
## The path to the private key we want to make github use
githubPrivateKey="/opt/wyb/private/wyb"
## The github-specific config for the .ssh config file
githubSshConfig="
Host github.com
    Hostname github.com
    User git
    PreferredAuthentications publickey
    IdentityFile ${githubPrivateKey}
    IdentitiesOnly yes"

# Functions
# Downloads terraform files and verifys pgp keys
downloadTerraform(){
  wget https://releases.hashicorp.com/terraform/${desiredTerraformVersion}/terraform_${desiredTerraformVersion}_linux_amd64.zip
  wget https://releases.hashicorp.com/terraform/${desiredTerraformVersion}/terraform_${desiredTerraformVersion}_SHA256SUMS
  wget https://releases.hashicorp.com/terraform/${desiredTerraformVersion}/terraform_${desiredTerraformVersion}_SHA256SUMS.sig

  # Get the hashicorp key from pool.sks-keyservers.net
  gpg --keyserver pool.sks-keyservers.net --recv-key ${hashiPublicKeyId}

  # Check that the fingerprint of the gpg matches what's on the hashicorp site
  fingerprint=`gpg --fingerprint ${hashiPublicKeyId} | grep "Key fingerprint" | cut -d"=" -f2 | sed 's/ //g'`
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
    
# Body
# Install zip
sudo apt-get install -y zip

# Create a /bin directory to store the terraform executable
mkdir -p ${terraformBinDir}
if [ ! -f terraform_${desiredTerraformVersion}_linux_amd64.zip ]; then
  downloadTerraform
fi
unzip -o terraform_${desiredTerraformVersion}_linux_amd64.zip -d ${terraformBinDir}
echo "export PATH=\${PATH}:${terraformBinDir}" >> /home/vagrant/.bashrc

# Check if the user already has a private directory for sensitive files.
if [ ! -d /opt/wyb/private ]; then
  echo "Creating a private directory for sensitive files"
  mkdir -p /opt/washyobutt/private
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
else
  # Relying on the user to know what they're doing.
  echo "You have a provisioning key, please make sure it's defined in you terraform.tfvars as provisionerPublicKey"
fi

# Need to do some work on the keys for github.  First check if .ssh/config exists
if [[ -f /home/vagrant/.ssh/config ]]; then
  echo "SSH config exists"
  #Now check if there's a config for github already.  We're erroring on the side of not messing with the user's setup.
  if ! grep -i "Hostname github.com" /home/vagrant/.ssh/config; then
    cat <<EOF >> /home/vagrant/.ssh/config
    ${githubSshConfig}
EOF
  fi
else
  touch /home/vagrant/.ssh/config
  cat <<EOF >> /home/vagrant/.ssh/config
  "${githubSshConfig}"
EOF

  #Our github ssh config is looking for /opt/wyb/private/wyb, so we'll check if that file is there.  If not, we'll create an ssh key with that name.
  if [[ ! -f ${githubPrivateKey} ]]; then
    ssh-keygen -f ${githubPrivateKey} -t rsa -b 4096 -C "wyb" -q -N ""
    echo "Created a private key for you at ${githubPrivateKey}.  Your ssh config has been updated to use this key for github access on the vagrant VM.  You will need to add the public key from ${githubPrivateKey}.pub to your github account, and request access as a collaborator to the project.  Feel free to use your own and reconfigure ssh as needed."
  fi
fi

#Link the .git hooks dir to the project hooks dir
if [[ ! -L /opt/wyb/.git/hooks ]]; then
  echo "not a symlink"
else
  echo "is symlink"
fi

#Install python2.7 and the pip packages I'm using
sudo apt-get update
sudo apt-get -y install python2.7 python-pip
pip install tweepy
pip install configparser
pip install awscli
