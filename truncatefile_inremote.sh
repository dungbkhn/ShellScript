#!/bin/bash

shopt -s dotglob
shopt -s nullglob

tempfilename="$1"

#neu co tham so thu hai
if [ "$2" ] ; then
	filename=$(echo "$2" | tr -d '\n' | xxd -r -p)
	
	
	#neu khong co tham so thu ba
	if [ ! "$3" ] ; then
		#file ton tai
		if [ -f "$filename" ] ; then
			filesize=$(wc -c "$filename" | awk '{print $1}')
			
			truncsize=$(( (filesize / (8*1024*1024) ) * (8*1024*1024) ))

			truncate -s "$truncsize" "$filename"
			
			rm "$tempfilename"
		
			exit 0
		else
			rm "$tempfilename"
		
			exit 0
		fi
		
	elif [ "$3" -eq 0 ] ; then
		filesize=$(wc -c "$filename" | awk '{print $1}')
		
		filesize=$(( $filesize - 8 ))

		truncate -s "$filesize" "$filename"
		
		rm "$tempfilename"
		
		exit 0
	else
		if [ -f "$filename" ] ; then
			cat "$tempfilename" >> "$filename"
		else
			mv "$tempfilename" "$filename"
		fi
		
		rm "$tempfilename"
		
		exit 0
	fi
fi
#chi co duy nhat 1 tham so
else
	exit 1
fi

