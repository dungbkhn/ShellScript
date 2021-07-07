#!/bin/bash

shopt -s dotglob
shopt -s nullglob

FILE='/home/dungnt/ShellScript/basename.sh'
mem_temp=/home/dungnt/ShellScript/temp

touch "$mem_temp""/""sdf.sdf"
mycommand="rm ""$mem_temp""/""*.*"
eval $mycommand


a=$(wc -c "$FILE" | awk '{print $1}')

echo $a



