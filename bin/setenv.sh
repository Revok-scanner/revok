#!/bin/bash

[ -z "$ROOT_PATH" ] && export ROOT_PATH=$(dirname $(dirname $(readlink -f $0)))

while read line ; do
  [[ ${line:0:1} == "#" ]] && continue
  [ ! -z "$line" ] && eval export $line
done < $ROOT_PATH/conf/revok.conf
