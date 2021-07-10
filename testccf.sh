#!/bin/bash

shopt -s dotglob
shopt -s nullglob

memtemp=/home/backup/.temp

#for COPY
copyfilesize="100MB"
truncsize=100000000

param1=$1
param2=$2
param3=$(xxd -r -p <<< "$3")


md5head_dest="md5head_dest.txt"
md5tail_dest="md5tail_dest.txt"
retval="255"

compare_file(){
	#echo 'compare_file'
	
	cmp "$1" "$2"
    
    #exit code
	#2,>2: file not found or other problems
	#1: diff
	#0: ok, same content

	return "$?"
}

rm "$memtemp""/""$md5head_dest"
rm "$memtemp""/""$md5tail_dest"
rm "$memtemp""/""output.beingcompare"

head -c 1024 "$param3" | md5sum | awk '{ print $1 }' > "$memtemp""/""$md5head_dest" 

compare_file "$param1" "$memtemp""/""$md5head_dest"

cmd=$?
				
if [ "$cmd" -eq 0 ]; then
	filesizedest=$(wc -c "$param1" | awk '{print $1}')
	cmd=$?

	if [ "$cmd" -eq 0 ] && [ "$filesizedest" ] && [ "$filesizedest" -gt 0 ] ; then
		cursizedest=$(($filesizedest / $truncsize))
		if [ "$cursizedest" -gt 1 ] ; then
			cursizedest=$(($cursizedest - 2))
			dd if="$param3" of="$memtemp""/""output.beingcompare" bs="$copyfilesize" count=1 skip="$cursizedest"
		else
			dd if="$param3" of="$memtemp""/""output.beingcompare" bs="$copyfilesize" count=1 skip="0"
		fi
		
		md5sum "$memtemp""/""output.beingcompare" | awk '{ print $1 }' > "$memtemp"/"$md5tail_dest"
		
		compare_file "$param2" "$memtemp"/"$md5tail_dest"

		cmd=$?
						
		if [ "$cmd" -eq 0 ]; then
			echo 'same'
			retval="1"
		else
			echo 'head same - tail diff'
			retval="2"
		fi
		
	else
		echo 'head same - tail fail'
		retval="3"
	fi
else
	echo '1024 head diff'
	retval="0"
fi

echo "$retval"


