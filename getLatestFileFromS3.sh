#!/bin/bash
set -e
read_dom () {
    local IFS=\>
    read -d \< ENTITY CONTENT
    local ret=$?
    TAG_NAME=${ENTITY%% *}
    ATTRIBUTES=${ENTITY#* }
    return $ret
}
i=0;
declare -a parsed
parse_dom () {
    if [[ $TAG_NAME = "Key" ]] ; then
        eval local $ATTRIBUTES
        parsed[0]="$CONTENT"

        IFS='/' read -ra ADDR <<< "$CONTENT"
        parsed[1]=${ADDR[1]}
        i=2
    elif [[ $TAG_NAME = "LastModified" ]] ; then
        eval local $ATTRIBUTES
        parsed[2]="$CONTENT"
        i=3
    fi
}

result='2010-08-01T18:40:59.000Z'
target=$(echo $1 | sed 's|\/|\\/|g')

while read_dom; do
    parse_dom
    if [ $i == 3 ] ; then
        i=0
        if [[ "${parsed[1]}" =~ $target ]] ; then
          if [[ ! "${parsed[1]}" =~ latest ]]; then
            todate=$(date -d "${parsed[2]}" "+%s" )
            cond=$(date -d "$result" "+%s")
            if [ ${todate} -ge ${cond} ];
            then
  	          result=${parsed[2]}
              return_value=${parsed[0]}
            fi
          fi
        fi
    fi
done

echo $return_value
