#!/bin/bash
 
shopt -s dotglob
shopt -s nullglob

pos=/home/dungnt/ShellScript
file_ori=/home/dungnt/ShellScript/mySync_final.sh

count=0
rm "$pos"/file300mb.txt
touch "$pos"/file300mb.txt

while [ $count -le 150000 ]
do
  cat "$file_ori" >> "$pos"/file300mb.txt
  count=$(( $count + 1 ))
done

