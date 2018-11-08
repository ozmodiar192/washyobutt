#!/bin/bash
## This script builds the wybWeb docker image and pushes it to the current ECR Repository at Amazon.  It takes two arguments; a path to a Dockerfile, and an optional debug.  It builds a docker image and tags it with the current commit.  If the current code has uncommited changes, you must specify --debug as the second argument.  This ensures all images with a github commit tag are true to what's in that commit.

scriptDir=`pwd`
#buildDir=${scriptDir}/../frontends/wybWeb
#buildDir=${scriptDir}/../backends/quoteServe
buildDir=${1}
# Derive the project name from the last directory of the build dir.  Must be lower-case
projectDir=`basename ${buildDir}`
projectName=`basename ${buildDir} | awk '{print tolower($0)}'`
tfDir=${scriptDir}/../terraform
debug=$2
currentCommit=`git log -n 1 --pretty=format:%h -- ${buildDir}`

# Authenticates with ECR.  Make sure your default aws profile has access, or export AWS_PROFILE=<some user with access>
authWithECR() { 
  $(aws ecr get-login --no-include-email --region us-east-1) 
}

# Gets the name of the ECR repo from Terraform
getECRId() {
  repo=`cd ${tfDir}/vpcPublic && terraform show | grep repository_url | cut -d"=" -f2 | tr -d '[:space:]'`
  echo "using repo \"${repo}\""
  repoName=`echo ${repo} | cut -d'/' -f2`
  echo "using repo name ${repoName}"
}

# Checks if the current codebase has uncommitted changes.  
checkChanges() {
  if git status ${buildDir} --porcelain | grep ${projectDir} > /dev/null && [ "${debug}" != "--debug" ]; then
    echo "You're attempting a formal build, but you have uncommited changes.  Please commit any changes and re-run"
    echo "If you are testing, please re-run this script with the --debug flag"
    exit 1
  elif [ "${debug}" == "--debug" ]; then
    echo "Debug build submitted" 
    tag="${projectName}-${currentCommit}-debug" 
  else
    echo "Proceeding with build using current commit value"
    tag=${projectName}-${currentCommit}
  fi
}    

# Executes a docker build
buildImage(){
  echo "debug: cd ${buildDir} && docker build -t ${projectName}:${tag} ."
  cd ${buildDir} && docker build -t ${projectName}:${tag} .
  echo "debug:  docker tag ${projectName}:${tag} ${repo}:${tag}"
  docker tag ${projectName}:${tag} ${repo}:${tag}
}

# Pushes an image to ecr
pushImage(){
  authWithECR
  echo "debug:  docker push ${repo}:${tag}"
  docker push ${repo}:${tag}
}

updateTag(){
  imagePath="${repo}:${tag}"
  task="${tfDir}/ecs/tasks/${projectDir}.json"
  echo "replacing image name with \"${imagePath}\"in ${task}"
  sed -i "s#\"image\"\: \".*\",#\"image\"\: \"${imagePath}\",#g" ${task}
}
  

checkChanges
getECRId
echo "Got ECR Repo ID ${repo}"
buildImage
pushImage
updateTag
