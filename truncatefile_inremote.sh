#!/bin/bash

shopt -s dotglob
shopt -s nullglob

tempfilename="$1"

filename=$(echo "$2" | tr -d '\n' | xxd -r -p)

#neu tham so thu ba = 0
if [ "$3" -eq 0 ] ; then
	#neu ton tai tham so thu tu = 0, copy total file --> remove old file
	if [ "$4" -eq 0 ] ; then
		rm "$filename"
		
		rm "$tempfilename"
	
		exit 0
	#neu la append va file ton tai
	elif [ -f "$filename" ] ; then
		filesize=$(wc -c "$filename" | awk '{print $1}')
		
		truncsize=$(( (filesize / (8*1024*1024) ) * (8*1024*1024) ))

		truncate -s "$truncsize" "$filename"
		
		rm "$tempfilename"
	
		exit 0
	fi
elif [ "$3" -eq 1 ] ; then
	if [ -f "$filename" ] ; then
		cat "$tempfilename" >> "$filename"
	else
		mv "$tempfilename" "$filename"
	fi
	
	rm "$tempfilename"
	
	exit 0
fi



