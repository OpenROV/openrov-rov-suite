#!/bin/bash
set -e

if [ $REAL_GIT_BRANCH -eq master ]
then
  while read package; do
  #  apt-cache madison $package
  #  apt-cache madison $package | awk '{print $1,$3}' >> manifest
    apt-cache policy $package | grep Candidate: | awk -v pkg_name=$package '{print pkg_name, $2}'
    apt-cache policy $package | grep Candidate: | awk -v pkg_name=$package '{print pkg_name, $2}' >> manifest
  done < inventory
else
  # When branching from development, you must also create a new manifest_release to lock the dependency versions
  cp manifest_release manifest
fi

cat manifest
