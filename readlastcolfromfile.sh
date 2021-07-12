#!/bin/bash
 
shopt -s dotglob
shopt -s nullglob

appdir=/home/dungnt/ShellScript/sshsyncapp
memtemp="$appdir"/.temp

copyfilesize="100MB"
truncsize=100000000
countsize=0
skipsize=0

count=0
filesize=0
md5hash=""
md5tailhash=""
len=0

# declare names as an indexed array
declare -a names

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

printf "./\n" > ./listfiles.txt

for pathname in ./*
do 
	if [ "$count" -eq 0 ] ; then
		if [ -d "$pathname" ] ; then 
			printf "%s/%s/0/0/0\n" "$pathname" "d" >> ./listfiles.txt
		else
			filesize=$(wc -c "$pathname" | awk '{print $1}')
			md5hash=$(head -c 1024 "$pathname" | md5sum | awk '{ print $1 }')
			md5tailhash=$(get_src_content_file_md5sum "$pathname")
			printf "%s/%s/%s/%s/%s\n" "$pathname" "f" "$filesize" "$md5hash" "$md5tailhash" >> ./listfiles.txt
		fi
	else
		if [ -d "$pathname" ] ; then 
			printf "%s/%s/0/0/0\n" "$pathname" "d" >> ./listfiles.txt
		else
			filesize=$(wc -c "$pathname" | awk '{print $1}')
			md5hash=$(head -c 1024 "$pathname" | md5sum | awk '{ print $1 }')
			md5tailhash=$(get_src_content_file_md5sum "$pathname")
			printf "%s/%s/%s/%s/%s\n" "$pathname" "f" "$filesize" "$md5hash" "$md5tailhash" >> ./listfiles.txt
		fi
	fi
	count=$(($count + 1))
done

count=0

while IFS=/ read beforeslash afterslash_1
do
	if [ "$afterslash_1" != "" ] ; then
		names[$count]="$afterslash_1"
		count=$(($count + 1))
    fi
done < ./listfiles.txt

len=${#names[@]}
echo "len:""$len"

# for loop that iterates over each element in arr
for i in "${names[@]}"
do
    echo $i
done
