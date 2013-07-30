#!/bin/bash

while : 
do
  echo "yeah yo"
  sleep 2
  for (( i=1 ; ((i-100)) ; i=(($i+1)) ))
  do
    echo -e -n "$i\r"
  done;
done
