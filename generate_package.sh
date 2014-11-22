#!/bin/bash
set -e

cat >> make_package.sh << __EOF__
#!/bin/bash
set -e
fpm -f -m info@openrov.com -s dir -t deb -a armhf
 -n openrov-onrov-suite
__EOF__

while read package; do
  echo package | awk '-d {print $1}' >> make_package.sh
done < manifest


cat >> make_package.sh << __EOF__
-v $VERSION_NUMBER-$REAL_GIT_BRANCH
--description 'OpenROV suite of projects that run on the ROV directly' .=/opt/openrov
__EOF__

cat make_package.sh
