#!/bin/bash
set -ex

if [ "$REAL_GIT_BRANCH" = "master" ]
then

  TEMPDIR=`mktemp -d`

  #for each line in the nightly-repos folder
  #get the latest file from the repo
  curl -o ${TEMPDIR}/nightlies.xml http://openrov-software-nightlies.s3-us-west-2.amazonaws.com
  ls ${TEMPDIR}/nightlies.xml
  while read package; do
    echo $package
  #  cat ${TEMPDIR}/nightlies.xml | ./getLatestFileFromS3.sh ${package}
    cat ${TEMPDIR}/nightlies.xml | ./getLatestFileFromS3.sh ${package} >> ${TEMPDIR}/latest_files.txt
  done < inventory


  cat ${TEMPDIR}/latest_files.txt
  #get the list of dependent files
  while read item; do
    echo $item | awk -F'[_/]' '{print $2 " " $3}' >> manifest
  done < ${TEMPDIR}/latest_files.txt

  rm -rf $TEMPDIR

  echo 'Manifest:'
  echo manifest
  echo '--End Manifest--'
else
  # When branching from development, you must also create a new manifest_release to lock the dependency versions
  cp manifest_release manifest
fi

cat manifest
