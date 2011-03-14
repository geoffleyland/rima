#! /bin/bash

YEAR=${1:-2011}

for suffix in lua cpp txt html
do
  for f in `find . -name "*.$suffix"`
  do
    echo $f
    cat $f | \
      sed -E "s/Copyright([^0-9]+)(20[0-9][0-9])\-(20[0-9][0-9])/Copyright\1\2-$YEAR/" | \
      sed -E "s/Copyright([^0-9]+)(20[0-9][0-9])([^\-])/Copyright\1\2-$YEAR\3/" | \
      sed "s/license.txt/LICENSE/" > \
      atempfile
    mv atempfile $f
  done
done

