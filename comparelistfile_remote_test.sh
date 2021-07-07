#!/bin/bash

shopt -s dotglob
shopt -s nullglob

memtemp=/home/backup/.temp

#for COPY
copyfilesize="100MB"
truncsize=100000000
countsize=0
skipsize=0

get_src_content_file_md5sum(){
	local param1=$1
	local cmd
	local filesizedest
	local cursizedest
	local mytemp="$memtemp"
	local kq
	
	rm "$mytemp""/output.beingcompare"
	
	filesizedest=$(wc -c "$param1" | awk '{print $1}')
	cmd=$?
	
	if [ "$cmd" -eq 0 ] && [ "$filesizedest" ] && [ "$filesizedest" -gt 0 ] ; then
		cursizedest=$(($filesizedest / $truncsize))
		if [ "$cursizedest" -gt 0 ] ; then
			cursizedest=$(($cursizedest - 1))
			dd if="$param1" of="$mytemp""/output.beingcompare" bs="$copyfilesize" count=2 skip="$cursizedest"
		else
			dd if="$param1" of="$mytemp""/output.beingcompare" bs="$copyfilesize" count=1 skip="0"
		fi
		
		kq=$(md5sum "$mytemp""/output.beingcompare" | awk '{ print $1 }')
		
	else
		kq="0"
	fi
	
	echo "$kq"
}


#ten file chua ds file tu phia local
param1=$1
#thu muc dang sync phia remote
param2=$2
#outputfilename 
param3=$3

# declare array
declare -a names
declare -a isfile
declare -a filesize
declare -a headmd5sum
declare -a tailmd5sum
declare -a hassamefile

declare -a names_remote
declare -a isfile_remote
declare -a filesize_remote
declare -a headmd5sum_remote
declare -a tailmd5sum_remote
declare -a hassamefile_remote

declare -a names_nt
declare -a filesize_nt
declare -a headmd5sum_nt
declare -a tailmd5sum_nt

declare -a names_remote_nt
declare -a filesize_remote_nt
declare -a headmd5sum_remote_nt
declare -a tailmd5sum_remote_nt
declare -a isselected_remote_nt

count=0

while IFS=/ read beforeslash afterslash_1 afterslash_2 afterslash_3 afterslash_4 afterslash_5
do
    names[$count]="$afterslash_1"
    isfile[$count]="$afterslash_2"
    filesize[$count]="$afterslash_3"
    headmd5sum[$count]="$afterslash_4"
    tailmd5sum[$count]="$afterslash_5"
    hassamefile[$count]=0
    count=$(($count + 1))
done < "$memtemp""/""$param1"

count=0

for pathname in "$param2"/*; do
	names_remote[$count]=$(basename "$pathname")
	hassamefile_remote[$count]=0
	
	if [ -d "$pathname" ] ; then 
		printf "%s/%s/0/0/0\n" "$pathname" "d" 
		isfile_remote[$count]="d"
		filesize_remote[$count]=0
		headmd5sum_remote[$count]=0
		tailmd5sum_remote[$count]=0
	else
		isfile_remote[$count]="f"
		filesize_remote[$count]=$(wc -c "$pathname" | awk '{print $1}')
		headmd5sum_remote[$count]=$(head -c 1024 "$pathname" | md5sum | awk '{ print $1 }')
		tailmd5sum_remote[$count]=$(get_src_content_file_md5sum "$pathname")
		printf "%s/%s/%s/%s/%s\n" "$pathname" "f" "${filesize_remote[$count]}" "${headmd5sum_remote[$count]}" "${tailmd5sum_remote[$count]}" 
	fi
	
	count=$(($count + 1))
done
