#!/bin/bash
set -e

#Duplicated switch settings from the underlying publish.sh


BASEURL=http://openrov-software-nightlies.s3-website-us-west-2.amazonaws.com/${DEB_CODENAME}/
IFS=$'\n'
BRANCH=$2
SUITEURL=${BASEURL}openrov-rov-suite/$1
export DIR=${PWD#}
TMPDIR="$DIR/.tmp"
mkdir -p $TMPDIR
TEMPDIR=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`
pushd $TEMPDIR

curl -O $SUITEURL
popd
#get the list of dependent files
for ITEM in `dpkg -I ${TEMPDIR}/${1} | grep Depends: | sed 's/ (=/_/g' | sed 's/)/_armhf.deb/g' | sed 's/Depends: //g' | sed 's/ //g' | tr ',' '\n'`
do
  RAWNAME=$(echo $ITEM | awk -F '[_]' '{print $1}')
  URL=$(cat ../nightly-repos | grep $RAWNAME | awk -F '[  ]' '{print $2}'|sed 's/?prefix=//' )
  DEBURL=${URL}${ITEM}

  echo "publishing $ITEM"
  ./publish.sh $DEBURL
done
./publish.sh $SUITEURL
echo "publishing $1"

rm -rf $TEMPDIR
