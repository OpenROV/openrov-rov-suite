#!/bin/bash
#docker run -t --rm -e "JENKINS_TOKEN_NAME=$JENKINS_TOKEN_NAME" -v $(pwd):/work -w /work smashwilson/curl /bin/bash get_latest_version_of_dependencies.sh
set -e


TEMPDIR=`mktemp -d`

#for each line in the nightly-repos folder
#get the latest file from the repo
curl -o ${TEMPDIR}/nightlies.xml http://openrov-software-nightlies.s3-us-west-2.amazonaws.com
ls ${TEMPDIR}/nightlies.xml
while read package; do
  #need to parse package name and prefix out of nightlies
  S3prefix=package | cut -d= -f2
  packagename=package | cut -d' ' -f1
  echo $packagename
  echo $S3prefix
#  cat ${TEMPDIR}/nightlies.xml | ./getLatestFileFromS3.sh ${package}
  cat ${TEMPDIR}/nightlies.xml | ./getLatestFileFromS3.sh ${S3prefix} >> ${TEMPDIR}/latest_files.txt
done < nightly-repos
#publish those files to the debian repo
BASEURL=http://openrov-software-nightlies.s3-website-us-west-2.amazonaws.com/
IFS=$'\n'
BRANCH='master'

cat ${TEMPDIR}/latest_files.txt
#get the list of dependent files
while read item; do
  DEBURL=${BASEURL}${item}
  echo $item
  echo "publishing $DEBURL"
  curl -g http://openrov-build-test.elasticbeanstalk.com:8080/job/OpenROV-generic-upload-deb-to-repo/buildWithParameters -d token=$JENKINS_TOKEN_NAME -d urlToDebPackage=$DEBURL -d branch=$BRANCH
done < ${TEMPDIR}/latest_files.txt

rm -rf $TEMPDIR
