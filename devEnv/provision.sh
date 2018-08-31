#!/bin/bash

#####################Variables

## The location we want to install our custom binaries
binDir="/home/vagrant/bin"
## The hashicorp GPG signature fingerprint, obtained from https://www.hashicorp.com/security.html
hashiFingerprint="91A6E7F85D05C65630BEF18951852D87348FFC4C"
## The ID of the HashiCorp public key, also from the site.
hashiPublicKeyID="51852D87348FFC4C"
## The version of terraform we want to install
desiredTerraformVersion="0.11.7"
## The terraform zip file name
terraformZipFile="terraform_${desiredTerraformVersion}_linux_amd64.zip"
## The terraform signature file name
terraformSigFile="terraform_${desiredTerraformVersion}_SHA256SUMS.sig"
## The terraform sums file name
terraformSumFile="terraform_${desiredTerraformVersion}_SHA256SUMS"
## The dynamoDB zip file name
dynamoZipFile="dynamodb_local_latest.zip"
## The dynamoDB sums file name
dynamoSumFile="dynamodb_local_latest.zip.sha256"
## An alias for starting dynamoDB
startDynamoAlias="alias dynamostart=\"cd ${binDir} && java -Djava.library.path=./DynamoDBLocal_lib -jar DynamoDBLocal.jar -sharedDb &\""
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
# A function to automatically append the tfvars file
terraformFunc="
function terraform (){
  if [ -f ../../private/terraform.tfvars ]; then
    case \$* in 
      apply* ) shift 1; command terraform apply -var-file=../../private/terraform.tfvars \"\$@\" ;;
      plan* ) shift 1; command terraform plan -var-file=../../private/terraform.tfvars \"\$@\" ;;
      destroy* ) shift 1; command terraform destroy -var-file=../../private/terraform.tfvars \"\$@\" ;;
      *) command terraform \"\$@\" ;;
    esac
  else
    echo \"Couldn't find tfvars file\"
    command terraform \"\$@\"
fi
}
"
## Dummy credentials for aws to allow local dynamo DB access
awsDummyCreds="
[default]
aws_access_key_id = thisisanaccesskey
aws_secret_access_key = thisisasecretkey
"


###################### Functions
# Downloads terraform files and verifys pgp keys
downloadTerraform(){
  wget https://releases.hashicorp.com/terraform/${desiredTerraformVersion}/${terraformZipFile}
  wget https://releases.hashicorp.com/terraform/${desiredTerraformVersion}/${terraformSumFile}
  wget https://releases.hashicorp.com/terraform/${desiredTerraformVersion}/${terraformSigFile}

  # Check that the fingerprint of the gpg matches what's on the hashicorp site
  checkFingerprint ${hashiPublicKeyID} ${hashiFingerprint}

   # Verify the list of terraform checksums against the signature. The download itself is not signed, only the sums.  Therefore, if the sums are correct, we can checksum the file and trust the download.  verifySignature ${terraformSigFile} ${terraformSumFile}

  # Now that we know the sha sums file is correct, we can check the sum of the download against it.
  verifyDownload ${terraformZipFile} ${terraformSumFile}
}

downloadDynamoLocal(){
  #Download the local dynamoDB client
  wget https://s3-us-west-2.amazonaws.com/dynamodb-local/${dynamoZipFile}
  wget https://s3-us-west-2.amazonaws.com/dynamodb-local/${dynamoSumFile}

  #Verify the checksum of the dynamo DB download
  verifyDownload ${dynamoZipFile} ${dynamoSumFile}
}


# takes the public key ID, and an expected fingerprint
checkFingerprint(){
  pubKeyID=${1}
  expectedFingerprint=${2}
  # Get the key from pool.sks-keyservers.net
  gpg --keyserver pool.sks-keyservers.net --recv-key ${pubKeyID}

  # Check that the fingerprint of the gpg matches what's expected
  fingerprint=`gpg --fingerprint ${pubKeyID} | grep "Key fingerprint" | cut -d"=" -f2 | sed 's/ //g'`
  if [ ${fingerprint} == ${expectedFingerprint} ]; then
    echo "Verified fingerprint!"
  else
    echo "Got a bad gpg signature.  Expected: ${expectedFingerprint} Got: ${fingerprint}"
    exit 1
  fi
}

#Takes a signature file, and a target file to check against the signature
verifySignature(){
  sigFile=${1}
  targetFile=${2}
  if gpg --verify ${sigFile}  ${targetFile} ; then
    echo "Verified the SHA256 Checksums"
  else
    echo "Could not verify checksums on ${targetFile}!"
    exit 1
  fi
}

#Takes a target file, and a sum file to check it against. Assumes a sha256 sum.
verifyDownload(){
  targFile=${1}
  sumFile=${2}
  filesig=`shasum -a 256 ${targFile}`
  if grep ${filesig} ${sumFile}; then
    echo "Download verified"
  else
    echo "SHA signature on ${targFile} not found in ${sumFile} download did not match!  Something is wrong."
    exit 1
  fi
}

# Unzips a file to the binDir.  Takes a zip file name as an argument
installFromZip(){
  zipFile=${1}
  mkdir -p ${binDir}
  unzip -o ${zipFile} -d ${binDir}
}

#Creates dummy credentials file for local dynamoDB access
createDynamoDummyCreds(){
  if [[ -f /home/vagrant/.aws/credentials ]]; then
    echo "refusing to clobber your existing aws credentials"
  else
    mkdir -p /home/vagrant/.aws
    tocuh /home/vagrant/.aws/credentials
cat <<EOF >> /home/vagrant/.aws/credentials
${awsDummyCreds}
EOF
  fi
}

#Aliases terraform to a function that automatically includes terraform.tfvars
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

# Creates a dynamostart command that starts up the localdynamo db in the background
startDynamoAlias(){
  if [[ -f /home/vagrant/.bash_aliases ]]; then
    echo "${startDynamoAlias}" >> /home/vagrant/.bash_aliases
  else
    touch /home/vagrant/.bash_aliases
    echo "${startDynamoAlias}" >> /home/vagrant/.bash_aliases
  fi
}

#Installs NodeJS, npm, and express-generator.
installNodejs(){
  sudo apt-get install -y nodejs-legacy
  sudo apt-get install -y npm
  sudo npm install express-generator -g
}

#Installs python, pip, and all libraries used on WYB 
installPython(){
  sudo apt-get -y install python2.7 python-pip
  pip install tweepy
  pip install configparser
  pip install awscli
}
    
# Checks for a provisioning key for terraform to use to provision ec instances.
checkForDeployerKey(){
  if [[ -f /opt/wyb/private/wyb_provisioner ]] && [[ -f /opt/wyb/private/wyb_provisioner.pub ]]; then
    deployerKeyExists=true
  else
    deployerKeyExists=false
  fi
}

#Checks for a github key for github access
checkForGithubKey(){
  if [[ -f ${githubPrivateKey} ]]; then
    githubKeyExists=true
  else
    githubKeyExists=false
  fi
}

#Checks for the twitter credentials in private dir
checkForTwitterCreds(){
  if [[ -f /opt/wyb/private/twitter-api.properties ]]; then
    twitterCredentialsExist=true
  else
    twitterCredentialsExist=false
  fi
}

# Checks if amazon credentials are defined in terraform.tfvars
checkForAWSCreds(){
  if find /opt/wyb -iname terraform.tfvars -print0 | xargs -0 grep accessKey > /dev/null 2>&1  && find /opt/wyb -iname terraform.tfvars -print0 | xargs -0 grep secretKey > /dev/null 2>&1 ; then
    AWSCredsExist=true
  else
    AWSCredsExist=false
  fi
}

#Creates a key as a courtesy to new github users
createGithubKey(){
    ssh-keygen -f ${githubPrivateKey} -t rsa -b 4096 -C "wyb" -q -N ""
}

#Creates a key for terraform provisioning
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

#Adds a specific ssh config to ensure github private key is used.
addGithubSSHConfig(){
 cat <<EOF >> /home/vagrant/.ssh/config
 ${githubSSHConfig}
EOF
}

    
########################## MAIN ##############################

# apt update and install zip
sudo apt-get update
sudo apt-get install -y zip

# Download and install terraform
if [ ! -f ${terraformZipFile} ]; then
  downloadTerraform
fi
installFromZip ${terraformZipFile}
terraformAlias

# Add bin dir to the path 
echo "export PATH=\${PATH}:${binDir}" >> /home/vagrant/.bashrc

#Install the local dyamoDB client, create an alias, and install java
downloadDynamoLocal
installFromZip ${dynamoZipFile}
startDynamoAlias
createDynamoDummyCreds
sudo apt-get install -y default-jre

# Install python, pip, and my packages
installPython

#Install nodejs and npm
installNodejs

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

#Our github ssh config is looking for ${githubPrivateKey}, so we'll check if that file is there.  If not, we'll create an ssh key with that name.
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


#Inform the user of next steps.
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

