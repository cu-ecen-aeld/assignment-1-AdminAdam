#!/bin/bash

filesdir=$1
searchstr=$2

if [ "$#" -ne 2 ]
then
  echo "Wrong number of input parameters"
  exit 1
elif [ ! -d $filesdir ]
then
  echo "File directory doesn't exist"
  exit 1
fi

X=$(find "$filesdir" -type f | wc -l)
Y=$(grep -r "$searchstr" $filesdir | wc -l)

echo "The number of files are $X and the number of matching lines are $Y"
exit 0
