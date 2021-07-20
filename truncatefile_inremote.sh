#!/bin/bash

shopt -s dotglob
shopt -s nullglob

tempfilename="$1"

filename=$(echo "$2" | tr -d '\n' | xxd -r -p)

uploadfilename="/home/backup/.temp/uploadfile.ending"

partialfile="/home/backup/.temp/partialfile.being"

catfileinremote="/home/backup/.temp/catfileinremote.sh"

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
		
		#co tempfile lai 1 byte
		filesize=$(wc -c "$uploadfilename" | awk '{print $1}')
		truncsize=$(( $filesize - 1 ))
		truncate -s "$truncsize" "$uploadfilename"
		
		#chuan bi doi ten
		newfilename="$filename"".concatenating"
		
		#neu da append xong
		if [ -f "$filename" ]; then
			
			filesize=$(wc -c "$filename" | awk '{print $1}')
			truncsize=$(( (filesize / (8*1024*1024) ) * (8*1024*1024) ))
			rm "$partialfile"
			dd if="$filename" of="$partialfile" bs=10MB count=2 iflag=skip_bytes skip="$truncsize"

			#chuan bi file cat
			touch "$catfileinremote"
			truncate -s 0 "$catfileinremote"
			echo 'cat "$1" >> "$2"' >> "$catfileinremote"
			echo 'rm "$1"' >> "$catfileinremote"

			#bat dau cat
			mv "$filename" "$newfilename"
			truncate -s "$truncsize" "$newfilename"
			
			bash "$catfileinremote" "$uploadfilename" "$newfilename" &
			
			while true; do
				if [ -f "$uploadfilename" ] ; then
					#echo 'sleep 1s'
					sleep 1
				else
					break
				fi
			done
			
			#cat "$uploadfilename" >> "$newfilename"
			#rm "$uploadfilename"
			
		#neu copy xong
		else
			mv "$uploadfilename" "$newfilename"
		fi

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



