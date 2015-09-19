#!/bin/bash
set -ex

#This script will take a package, sign the package, and then move
#the pacakge in to the S3 backed debian repository.  It requires a gpg keyring to
#be in a relative path docker/deb-repository/gnupg.

export DIR=${PWD#}

#standard command-line argument handler: http://www.shelldorado.com/goodcoding/cmdargs.html
fileURL=
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
      \?)		# unknown flag
      	  echo >&2 \
	  "usage: $0 [-c deb_codename] \
               [-m deb_component] \
               [-a aws_credentials_filename] \
               [-s aws_secret] \
               [-k aws_key] \
               [-p gpg_passphrase] \
               [-P gpg_passphrase_filename] \
               [-i gpg_key_id] "
	  exit 1;;
    esac
done
shift `expr $OPTIND - 1`


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



docker run \
	-t \
  --rm=true \
	-v $DIR/docker/deb-repository/gnupg/:/root/.gnupg \
	-v $OUTPUT_DIR/packages:/tmp/packages \
	-e HOME=/root openrov/debs3 verify \
    --fix-manifests \
		--bucket=openrov-deb-repository \
		-c $DEB_CODENAME \
                -m $DEB_COMPONENT \
		--access-key-id=$AWSKEY \
		--secret-access-key=$AWSSECRET \
