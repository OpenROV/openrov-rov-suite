#!/bin/bash
set -ex

if [ "$REAL_GIT_BRANCH" = "master" ]
then
  echo "deb http://deb-repo.openrov.com/ master debian" | sudo tee -a /etc/apt/sources.list
  sudo apt-get update -q  || true
  while read package; do
  #  apt-cache madison $package
  #  apt-cache madison $package | awk '{print $1,$3}' >> manifest
    apt-cache policy $package | grep Candidate: | awk -v pkg_name=$package '{print pkg_name, $2}'
    apt-cache policy $package | grep Candidate: | awk -v pkg_name=$package '{print pkg_name, $2}' >> manifest
  done < inventory
  echo 'Manifest:'
  echo manifest
  echo '--End Manifest--'
else
  # When branching from development, you must also create a new manifest_release to lock the dependency versions
  cp manifest_release manifest
fi

cat manifest
