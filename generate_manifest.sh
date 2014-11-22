#!/bin/bash
set -e
while read package; do
  apt-cache madison package | awk '{print $1,$3}' >> manifest
done <inventory
