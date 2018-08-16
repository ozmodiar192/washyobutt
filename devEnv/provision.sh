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
githubPrivateKey="/opt/wyb/private/wyb_github"
## The github-specific config for the .ssh config file
githubSSHConfig="
Host github.com
    Hostname github.com
    User git
    PreferredAuthentications publickey
    IdentityFile ${githubPrivateKey}
    IdentitiesOnly yes"
terraformFunc="
function terraform (){
  if [ -f ../../private/terraform.tfvars ]; then
    case \$* in 
      apply* ) shift 1; command terraform apply -var-file=../../private/terraform.tfvars \"\$@\" ;;
      destroy* ) shift 1; command terraform destroy -var-file=../../private/terraform.tfvars \"\$@\" ;;
      *) command terraform \"\$@\" ;;
    esac
  else
    echo \"Couldn't find tfvars file\"
    command terraform \"\$@\"
fi
}
"


###################### Functions
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

installTerraform(){
  mkdir -p ${terraformBinDir}
  unzip -o terraform_${desiredTerraformVersion}_linux_amd64.zip -d ${terraformBinDir}
  echo "export PATH=\${PATH}:${terraformBinDir}" >> /home/vagrant/.bashrc
  terraformAlias
}

terraformAlias(){
  if [[ -f /home/vagrant/.bash_aliases ]]; then
cat <<EOF >> /home/vagrant/.bash_aliases
${terraformFunc}
EOF
  else
    touch /home/vagrant/.bash_aliases
cat <<EOF >> /home/vagrant/.bash_aliases
${terraformFunc}
EOF
fi
}

installNodejs(){
  sudo apt-get install -y nodejs
  sudo apt-get install -y npm
}

installPython(){
  sudo apt-get -y install python2.7 python-pip
  pip install tweepy
  pip install configparser
  pip install awscli
}

    

checkForDeployerKey(){
  if [[ -f /opt/wyb/private/wyb_provisioner ]] && [[ -f /opt/wyb/private/wyb_provisioner.pub ]]; then
    deployerKeyExists=true
  else
    deployerKeyExists=false
  fi
}

checkForGithubKey(){
  if [[ -f ${githubPrivateKey} ]]; then
    githubKeyExists=true
  else
    githubKeyExists=false
  fi
}

checkForTwitterCreds(){
  if [[ -f /opt/wyb/private/twitter-api.properties ]]; then
    twitterCredentialsExist=true
  else
    twitterCredentialsExist=false
  fi
}

checkForAWSCreds(){
  if find /opt/wyb -iname terraform.tfvars -print0 | xargs -0 grep accessKey > /dev/null 2>&1  && find /opt/wyb -iname terraform.tfvars -print0 | xargs -0 grep secretKey > /dev/null 2>&1 ; then
    AWSCredsExist=true
  else
    AWSCredsExist=false
  fi
}

createGithubKey(){
    ssh-keygen -f ${githubPrivateKey} -t rsa -b 4096 -C "wyb" -q -N ""
}

createDeployerKey(){
  ssh-keygen -f /opt/wyb/private/wyb_provisioner -t rsa -b 4096 -C "wyb_provisioning" -q -N ""
  wybProvisionerPub=`cat /opt/wyb/private/wyb_provisioner.pub`
  if [ -f /opt/wyb/terraform/vpc_public/terraform.tfvars ]; then
    echo "appending new public key to your terraform.tfvars"
    echo "provisionerPublicKey = \"${wybProvisionerPub}\"" >> /opt/wyb/terraform/vpc_public/terraform.tfvars
  else
    touch /opt/wyb/terraform/vpc_public/terraform.tfvars
    echo "provisionerPublicKey = \"${wybProvisionerPub}\"" >> /opt/wyb/terraform/vpc_public/terraform.tfvars
  fi
}

addGithubSSHConfig(){
 cat <<EOF >> /home/vagrant/.ssh/config
 ${githubSSHConfig}
EOF
}

    
########################## MAIN

# apt update and install zip
sudo apt-get update
sudo apt-get install -y zip

# Create a /bin directory to store the terraform executable
if [ ! -f terraform_${desiredTerraformVersion}_linux_amd64.zip ]; then
  downloadTerraform
fi
installTerraform

# Install python, pip, and my packages
installPython

# Check if the user already has a private directory for sensitive files.
if [ ! -d /opt/wyb/private ]; then
  echo "Creating a private directory for sensitive files"
  mkdir -p /opt/wyb/private
fi

#Look for a wyb deployer key
checkForDeployerKey
if [ ${deployerKeyExists} = false ]; then
  createDeployerKey
fi

# Need to do some work on the keys for github.  First check if .ssh/config exists
if [[ -f /home/vagrant/.ssh/config ]]; then
  #check if there's a config for github already.  We're erroring on the side of not messing with the user's setup throughout this process.
  if ! grep -i "Hostname github.com" /home/vagrant/.ssh/config; then
    addGithubSSHConfig
  fi
else
  touch /home/vagrant/.ssh/config
  addGithubSSHConfig
fi

#Our github ssh config is looking for /opt/wyb/private/wyb, so we'll check if that file is there.  If not, we'll create an ssh key with that name.
checkForGithubKey
if [[ ${githubKeyExists} = false ]]; then
  createGithubKey
fi

#Link the .git hooks dir to the project hooks dir
if [[ ! -L /opt/wyb/.git/hooks ]]; then
  rm -rf /opt/wyb/.git/hooks
  cd /opt/wyb/.git
  ln -s ../hooks .
fi

## Do some checks so we can inform the user of next steps
checkForAWSCreds
checkForTwitterCreds

#Inform the user of next steps
echo "************************************  SUMMARY *****************************************"

if [ ${deployerKeyExists} = false ]; then
  echo "I created a deployer key for you in /opt/wyb/private and appended the public key to your terraform.tfvars file as provisionerPublicKey.  This key is for provisioning only"
else
  echo "You have a provisioning key already.  The public (.pub) should be in your terraform.tfvars file as provisionerPublicKey."
fi

if [[ ${githubKeyExists} = false ]]; then
  echo "I automatically set your ssh configuration to use the key ${githubPrivateKey}, and I created a keypair for you.  If you'd like to use this for github access, you'll need to upload the public key (.pub) to your github account.  Otherwise, please edit your ssh settings in /home/vagrant/.ssh/config to use your own private key."
else
  echo "I set up your /home/vagrant/.ssh/config file to use your existing key ${githubPrivateKey} for access to github."
fi

if [[ ${twitterCredentialsExist} = false ]]; then
  echo "You will need the twitter credentials property files for access to the twitter commit hook.  If you'd like to use it, please contact Matt."
fi

if [[ ${AWSCredsExist} = false ]]; then
  echo "Please contact Matt for a WYB Amazon account.  Put your access and secret keys in the terraform.tfvars file(s) as accessKey and secretKey respectively" 
fi

