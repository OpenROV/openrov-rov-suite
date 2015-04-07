#!/bin/bash
#docker run -t --rm -e "JENKINS_TOKEN_NAME=$JENKINS_TOKEN_NAME"-v $(pwd):/work -w /work smashwilson/curl /bin/bash publish_to_debian_repo.sh openrov-rov-suite_30.0.0~~pre-release.70.d71e4da_armhf.deb pre-release
set -e


BASEURL=http://openrov-software-nightlies.s3-website-us-west-2.amazonaws.com/
IFS=$'\n'
BRANCH=$2
SUITEURL=${BASEURL}openrov-rov-suite/$1

TEMPDIR=`mktemp -d` && pushd $TEMPDIR
curl -O $SUITEURL
popd
#get the list of dependent files
for ITEM in `dpkg -I ${TEMPDIR}/${1} | grep Depends: | sed 's/ (=/_/g' | sed 's/)/_armhf.deb/g' | sed 's/Depends: //g' | sed 's/ //g' | tr ',' '\n'`
do
  RAWNAME=$(echo $ITEM | awk -F '[_]' '{print $1}')
  URL=$(cat nightly-repos | grep $RAWNAME | awk -F '[  ]' '{print $2}'|sed 's/?prefix=//' )
  DEBURL=${URL}${ITEM}

  echo "publishing $ITEM"
  curl -g http://openrov-build-test.elasticbeanstalk.com:8080/job/OpenROV-generic-upload-deb-to-repo/buildWithParameters -d token=$JENKINS_TOKEN_NAME -d urlToDebPackage=$DEBURL -d branch=$BRANCH
done
curl -g http://openrov-build-test.elasticbeanstalk.com:8080/job/OpenROV-generic-upload-deb-to-repo/buildWithParameters -d token=$JENKINS_TOKEN_NAME -d urlToDebPackage=$SUITEURL -d branch=$BRANCH
echo "publishing $1"

rm -rf $TEMPDIR
