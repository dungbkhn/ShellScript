#!/bin/bash

shopt -s dotglob
shopt -s nullglob

tempfilename="$1"

filename=$(echo "$2" | tr -d '\n' | xxd -r -p)

endfilename="/home/backup/.temp/readyfile.ending"

partialfile="/home/backup/.temp/partialfile.being"

truncatestatusfile="/home/backup/.temp/trstatusfile.being"

#echo "filename ban dau:""$filename" >> /home/backup/luutru.txt

#neu tham so thu ba = 0
if [ "$3" -eq 0 ] ; then
	#neu ton tai tham so thu tu = 0, copy total file --> remove old file
	if [ "$4" -eq 0 ] ; then
		
		rm "$filename"
		
		rm "$tempfilename"

		rm "$endfilename"
		
		rm "$truncatestatusfile"
		
		touch "$truncatestatusfile"

		echo "1" >> "$truncatestatusfile"
		
		exit 0
	#neu la append (ktra file ton tai)
	elif [ -f "$filename" ] ; then
		rm "$endfilename"
		
		rm "$truncatestatusfile"
		
		touch "$truncatestatusfile"

		echo "2" >> "$truncatestatusfile"
		
		rm "$partialfile"
		
		filesize=$(wc -c "$filename" | awk '{print $1}')
		
		truncsize=$(( (filesize / (8*1024*1024) ) * (8*1024*1024) ))
		
		dd if="$filename" of="$partialfile" bs=10MB count=2 iflag=skip_bytes skip="$truncsize"
		
		truncate -s "$truncsize" "$filename"
		
		mv "$filename" "$endfilename"
		
		echo "$truncsize" >> "$truncatestatusfile"
		
		rm "$tempfilename"

		exit 0
	fi
elif [ "$3" -eq 1 ] ; then
	if [ -f "$endfilename" ] ; then
		cat "$tempfilename" >> "$endfilename"
	else
		mv "$tempfilename" "$endfilename"
	fi
	
	rm "$tempfilename"
	
	exit 0
#"$3" -eq 2
else
	if [ "$4" -eq 0 ] ; then

		filesize=$(wc -c "$endfilename" | awk '{print $1}')
		filesize=$(( $filesize - 1 ))
		truncate -s "$filesize" "$endfilename"
			
		exit 0
		
	elif [ "$4" -eq 1 ] ; then
		mv "$endfilename" "$filename"
		
		exit 0
	else
		count=0
		while IFS= read -r line ; do
			if [ "$count" -eq 0 ] ; then
				appendorcopy="$line"
			else
				truncsize="$line"
			fi
			count=$(( $count + 1 ))
		done < "$truncatestatusfile"
		
		if [ "$appendorcopy" -eq 1 ] ; then
			rm "$endfilename"
		else
			mv "$endfilename" "$filename"
			truncate -s "$truncsize" "$filename"
			cat "$partialfile" >> "$filename"
		fi
		
		exit 0
	fi
fi



