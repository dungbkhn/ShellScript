#!/bin/bash

shopt -s dotglob
shopt -s nullglob

tempfilename="$1"

filename=$(echo "$2" | tr -d '\n' | xxd -r -p)

waitfilename="/home/backup/.temp/readyfile.being"

#neu tham so thu ba = 0
if [ "$3" -eq 0 ] ; then
	#neu ton tai tham so thu tu = 0, copy total file --> remove old file
	if [ "$4" -eq 0 ] ; then
		rm "$filename"
		
		rm "$tempfilename"
		
		rm "$waitfilename"
	
		exit 0
	#neu la append va file ton tai
	elif [ -f "$filename" ] ; then
		#filesize=$(wc -c "$filename" | awk '{print $1}')
		
		#truncsize=$(( (filesize / (8*1024*1024) ) * (8*1024*1024) ))

		#truncate -s "$truncsize" "$filename"
		
		rm "$tempfilename"
		
		rm "$waitfilename"
	
		exit 0
	fi
elif [ "$3" -eq 1 ] ; then
	if [ -f "$waitfilename" ] ; then
		cat "$tempfilename" >> "$waitfilename"
	else
		#if [ -f "$filename" ] ; then
		#	mv "$filename" "$waitfilename"
		#	cat "$tempfilename" >> "$waitfilename"
		#else
		#	mv "$tempfilename" "$waitfilename"
		#fi
		mv "$tempfilename" "$waitfilename"
	fi
	
	rm "$tempfilename"
	
	if [ "$4" -eq 0 ] ; then
		exit 0
	else
		filesize=$(wc -c "$waitfilename" | awk '{print $1}')
		if [ "$filesize" ] && [ "$filesize" -gt 0 ] ; then
			filesize=$(( $filesize - 1 ))
			truncate -s "$filesize" "$waitfilename"
		fi
		exit 0
	fi
	
#"$3" -ne 0 and 1
else
	#mv "$waitfilename" "$filename"
	
	if [ ! -f "$filename" ] ; then
		mv "$waitfilename" "$filename"
	else
		filesize=$(wc -c "$filename" | awk '{print $1}')
		
		truncsize=$(( (filesize / (8*1024*1024) ) * (8*1024*1024) ))

		truncate -s "$truncsize" "$filename"
		
		cat "$waitfilename" >> "$filename"
		
		rm "$waitfilename"
	fi
	
	#tinh hash cua file tao ra, so sanh voi hash gui len tu local
	
	exit 0

fi



