#!/bin/bash

shopt -s dotglob
shopt -s nullglob

file_ori=/home/dungnt/ShellScript/dirtest1/a.txt
dir_dest=/home/dungnt/ShellScript/dirtest2/
curfilename="a.txt"


check_content_file(){
	#echo 'check_content_file'
	local param1=$1
	local param2=$2
	
	cmp "$param1" "$param2"
    
    #exit code
	#2,>2: file not found or other problems
	#1: diff
	#0: ok, same content

	return "$?"
}

check_content_file "$file_ori" "$dir_dest""$curfilename"
funcresult=$?

echo "$funcresult"
