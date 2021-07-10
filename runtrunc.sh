#!/bin/bash

shopt -s dotglob
shopt -s nullglob

#dir_contain_shell_file=/home/backup/trunc
dir_dest=/home/backup/.temp
#dir_dest=/home/dungnt/ShellScript/sshsyncapp/.temp
input_file=truncatefile_inremote.txt

filename="/"
truncsize=0

if [ ! -f "$dir_dest"/"$input_file" ] ; then
	exit 1
fi

c=0
while IFS=/ read beforeslash 
do
	if [ "$c" -eq 0 ] ; then
		truncsize="$beforeslash"
	elif [ "$c" -eq 1 ] ; then
		filename="$beforeslash"
	else
		break
	fi
	c=$(($c + 1))
done < "$dir_dest"/"$input_file"

truncate -s "$truncsize" "$filename" > /dev/null

exit "$?"
