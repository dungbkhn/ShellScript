#!/bin/bash

shopt -s dotglob
shopt -s nullglob

tempfilename="$1"

filename=$(echo "$2" | tr -d '\n' | xxd -r -p)

uploadfilename="/home/backup/.temp/uploadfile.ending"

partialfile="/home/backup/.temp/partialfile.being"

#truncatestatusfile="/home/backup/.temp/trstatusfile.being"

#echo "filename ban dau:""$filename" >> /home/backup/luutru.txt

#neu tham so thu ba = 0
if [ "$3" -eq 0 ] ; then
	#neu ton tai tham so thu tu = 0, copy total file --> remove old file
	if [ "$4" -eq 0 ] ; then
		
		rm "$filename"
		
		rm "$tempfilename"
		
		rm "$uploadfilename"

		exit 0
	#neu la append (ktra file ton tai)
	elif [ -f "$filename" ] ; then
	
		rm "$uploadfilename"

		rm "$tempfilename"

		exit 0
	fi
elif [ "$3" -eq 1 ] ; then
	if [ -f "$uploadfilename" ] ; then
		cat "$tempfilename" >> "$uploadfilename"
	else
		mv "$tempfilename" "$uploadfilename"
	fi
	
	rm "$tempfilename"
	
	exit 0
#"$3" -eq 2
else
	if [ "$4" -eq 0 ] ; then
		newfilename="$filename"".concatenating"
		
		#neu da append xong
		if [ -f "$filename" ]; then
			mv "$filename" "$newfilename"
			filesize=$(wc -c "$newfilename" | awk '{print $1}')
			truncsize=$(( (filesize / (8*1024*1024) ) * (8*1024*1024) ))
			rm "$partialfile"
			dd if="$newfilename" of="$partialfile" bs=10MB count=2 iflag=skip_bytes skip="$truncsize"
			truncate -s "$truncsize" "$newfilename"
			cat "$uploadfilename" >> "$newfilename"
			rm "$uploadfilename"
		#neu copy xong
		else
			mv "$uploadfilename" "$newfilename"
		fi
		
		#phai lay lai filesize
		filesize=$(wc -c "$newfilename" | awk '{print $1}')
		filesize=$(( $filesize - 1 ))
		truncate -s "$filesize" "$newfilename"

		exit 0
		
	elif [ "$4" -eq 1 ] ; then
		mv "$filename"".concatenating" "$filename"
		exit 0
	else
		if [ "$5" -eq 0 ] ; then
			rm "$filename"".concatenating"
		else
			mv "$filename"".concatenating" "$filename"
			filesize="$5"
			truncsize=$(( (filesize / (8*1024*1024) ) * (8*1024*1024) ))
			truncate -s "$truncsize" "$filename"
			cat "$partialfile" >> "$filename"
		fi
		
		exit 0
	fi
fi



