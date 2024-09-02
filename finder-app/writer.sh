#!/bin/bash

writefile=$1
writestr=$2

if [ "$#" -ne 2 ]
then
  echo "Wrong number of input parameters"
  exit 1
fi

mkdir -p "$(dirname "$writefile")"
touch "$writefile"
echo "$writestr" > $writefile

if [  ! -f $writefile ]
then
  echo "Not able to create file"
  exit 1
fi
exit 0
