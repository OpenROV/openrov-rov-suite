#!/bin/bash
set -e

cat >> make_package.sh << __EOF__
#!/bin/bash
set -e
set -x
__EOF__

echo -n "fpm -f -m info@openrov.com -s dir -t deb -a armhf -n openrov-rov-suite" >> make_package.sh
if [ "$REAL_GIT_BRANCH" = "master" ]
then
  COMPARATOR=">="
else
  COMPARATOR="="
fi

while read package; do
  if [[ "$package" =~ ^openrov-image-customization.* ]]; then
    echo -n $package | awk -v COMPARATOR=$COMPARATOR 'BEGIN{ORS="";} {!seen[$1]++} {print " --deb-pre-depends", "\""$1" ("COMPARATOR $2")\""}'
    echo -n $package | awk -v COMPARATOR=$COMPARATOR 'BEGIN{ORS="";} {!seen[$1]++} {print " --deb-pre-depends", "\""$1" ("COMPARATOR $2")\""}' >> make_package.sh
  else
    echo -n $package | awk -v COMPARATOR=$COMPARATOR 'BEGIN{ORS="";} {!seen[$1]++} {print " -d", "\""$1" ("COMPARATOR $2")\""}'
    echo -n $package | awk -v COMPARATOR=$COMPARATOR 'BEGIN{ORS="";} {!seen[$1]++} {print " -d", "\""$1" ("COMPARATOR $2")\""}' >> make_package.sh
  fi
done < manifest

if [ "$REAL_GIT_BRANCH" = "stable" ]
then
  echo -n " -v $VERSION_NUMBER~$BUILD_NUMBER.`git rev-parse --short HEAD` --description 'OpenROV suite of projects that run on the ROV directly' ./suite=/opt/openrov" >> make_package.sh
else
  echo -n " -v $VERSION_NUMBER~~$REAL_GIT_BRANCH.$BUILD_NUMBER.`git rev-parse --short HEAD` --description 'OpenROV suite of projects that run on the ROV directly' ./suite=/opt/openrov" >> make_package.sh
fi

cat make_package.sh
