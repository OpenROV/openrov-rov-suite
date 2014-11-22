#!/bin/bash
set -e
while read package; do
#  apt-cache madison $package
#  apt-cache madison $package | awk '{print $1,$3}' >> manifest
  apt-cache policy $package | grep Candidate: | awk -v pkg_name=$package '{print pkg_name, $2}'
  apt-cache policy $package | grep Candidate: | awk -v pkg_name=$package '{print pkg_name, $2}' >> manifest
done < inventory

cat manifest
