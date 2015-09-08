#!/bin/bash
set -x
set -e

#This script will take a package, sign the package, and then move
#the pacakge in to the S3 backed debian repository.  It requires a gpg keyring to
#be in a relative path docker/deb-repository/gnupg.

export DIR=${PWD#}
TMPDIR="$DIR/.tmp"
mkdir -p $TMPDIR
OUTPUT_DIR=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`
mkdir $OUTPUT_DIR/packages
#standard command-line argument handler: http://www.shelldorado.com/goodcoding/cmdargs.html
filename=
while getopts c:m:a:s:k:p:i:f: opt
do
    case "$opt" in
      c)  DEB_CODENAME="$OPTARG";;
      m)  DEB_COMPONENT="$OPTARG";;
      a)  AWS_CREDENTIALS="$OPTARG";;
      k)  AWSKEY="$OPTARG";;
      s)  AWSSECRET="$OPTARG";;
      p)  GPG_PASSPHRASE="$OPTARG";;
      P)  GPG_PASSPHRASE_FILE="$OPTARG";;
      i)  KEYID="$OPTARG";;
      f)  filename="$OPTARG";;
      \?)		# unknown flag
      	  echo >&2 \
	  "usage: $0 [-c deb_codename] \
               [-m deb_component] \
               [-a aws_credentials_filename] \
               [-s aws_secret] \
               [-k aws_key] \
               [-p gpg_passphrase] \
               [-P gpg_passphrase_filename] \
               [-i gpg_key_id] \
               [-f filename] [file ...]"
	  exit 1;;
    esac
done
shift `expr $OPTIND - 1`

while test $# -gt 0; do
  filename=$1
  shift
done

if [ "$DEB_CODENAME" = "" ]; then
        echo "Please set the DEB_CODENAME environment variable to define into what debian repo we should upload the .deb files."
        exit 1
fi

if [ "$DEB_COMPONENT" = "" ]; then
        echo "Please set the DEB_COMPONENT environment variable to define into what debian component we should upload the .deb files."
        exit 1
fi

if [ "$AWS_CREDENTIALS " != "" ]; then
        . $AWS_CREDENTIALS # this is a environment variable that is set by the Jenkins Credentials Binding Plugin (see below)
                           # and it contains the path to a file with the AWS credentials as KEY=Value
        AWSKEY=$AWSAccessKeyId
        AWSSECRET=$AWSSecretKey
fi

if [ "$AWSKEY " = "" ]; then
        echo "Please set the AWSKEY environment variable containing the path to a file with the key/value pairs for AWSKEY and AWSSECRET"
        exit 1
fi

if [ "$AWSSECRET " = "" ]; then
        echo "Please set the AWSSECRET environment variable containing the path to a file with the key/value pairs for AWSKEY and AWSSECRET"
        exit 1
fi

if [ "$GPG_PASSPHRASE_FILE" != "" ]; then
        echo "This option needs to be updated to read the file in to the GPG_PASSPHRASE variable."
        exit 1
fi

if [ "$GPG_PASSPHRASE" = "" ]; then
        echo "Please set the GPG_PASSPHRASE environment variable to the passphrase used for the GPG key."
        exit 1
fi

if [ "$KEYID" = "" ]; then
        echo "Please set the KEYID environment variable containing the id of the GPG key used to sign the packages."
        exit 1
fi

if [ "$filename" = "" ]; then
        echo "Filename is required."
        exit 1
fi


#docker pull openrov/debs3

cp $filename $OUTPUT_DIR/packages/

ls $OUTPUT_DIR/packages/

item=$(basename $filename)
chmod 777  $OUTPUT_DIR/packages
chmod 777  $OUTPUT_DIR/packages/${item}

# Docker command descrioption:
# -t assigns a pseudo tty, we need that for gpg (used for signing packages and the deb repo)
# -v /host/path:/container/path  mapps the host path to the container path read/write
#    The packages folder contains the debian packages
#    the $GPG_PASSPHRASE_FILE is a path to the passphrase. This file and the environment variable is created and maintained by
#    the Credentials Binding Plugin for Jenkins (https://wiki.jenkins-ci.org/display/JENKINS/Credentials+Binding+Plugin)
# -e HOME=  sets the environment variable HOME

#sign the file
docker run \
	-t \
  --rm=true \
	-v $DIR/docker/deb-repository/gnupg/:/root/.gnupg \
	-v $OUTPUT_DIR/packages:/tmp/packages \
	-e HOME=/root --entrypoint dpkg-sig openrov/debs3 \
	 -k $KEYID \
		-g "--passphrase '${GPG_PASSPHRASE}'" \
		-s openrov \
		/tmp/packages/${item}

# hack: try to overwrite the file with one that is already in the repo
#       and use that as the file to upload. Prevent the same file being
#       signed a second time from breaking the existing manifests
#       in the repository. https://github.com/krobertson/deb-s3/issues/46
set +e
  wget http://deb-repo.openrov.com/pool/o/op/${item} -O $OUTPUT_DIR/packages/${item}_tmp && mv $OUTPUT_DIR/packages/${item}_tmp $OUTPUT_DIR/packages/${item}
set -e

docker run \
	-t \
  --rm=true \
	-v $DIR/docker/deb-repository/gnupg/:/root/.gnupg \
	-v $OUTPUT_DIR/packages:/tmp/packages \
	-e HOME=/root openrov/debs3 upload \
		--bucket=openrov-deb-repository \
		-c $DEB_CODENAME \
                -m $DEB_COMPONENT \
                --preserve-versions \
		--access-key-id=$AWSKEY \
		--secret-access-key=$AWSSECRET \
		--sign=$KEYID \
		--gpg-options="--passphrase '${GPG_PASSPHRASE}'" \
		/tmp/packages/${item}

rm -rf $TMPDIR
