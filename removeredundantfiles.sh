#!/bin/bash


shopt -s dotglob
shopt -s nullglob
 
dir_ori=/home/dungnt/ShellScript/dirtest1
dir_dest=/home/dungnt/ShellScript/dirtest2
mem_temp=/home/dungnt/ShellScript/temp


remove_redundant_files(){
	local param1=$1
	local param2=$2
	local pathname
	local curbasename
	local curfilename
	local findresult
	local cmd
	
	
	for pathname in "$param2"/*; do
		
		if [ -d "$pathname" ]; then
			#lay ten thu muc
			curbasename=$(basename "$pathname")
			findresult=$(find "$param1" -type d -name "$curbasename")
			cmd=$?
			#neu tim thay
			if [ "$cmd" -eq 0 ] && [ "$findresult" ] ; then
				echo 'thay thu muc'
			else
				rm -r "$param2"/"$curbasename"/
			fi
		else
			#lay ten file
			curfilename=$(basename "$pathname")
			findresult=$(find "$param1" -type f -name "$curfilename")
			cmd=$?
			#neu tim thay
			if [ "$cmd" -eq 0 ] && [ "$findresult" ] ; then
				echo 'thay file'
			else
				rm "$param2"/"$curfilename"
			fi
		fi
	done
}

remove_redundant_files "$dir_ori" "$dir_dest"
