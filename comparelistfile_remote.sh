#!/bin/bash

shopt -s dotglob
shopt -s nullglob

memtemp=/home/backup/.temp

#for COPY
copyfilesize="10MB"
truncsize=10000000


get_src_content_file_md5sum(){
	local param1=$1
	local cmd
	local filesizedest
	local cursizedest
	local mytemp="$memtemp"
	local kq
	
	rm "$mytemp""/output.beingcompare" > /dev/null 2>&1
	
	filesizedest=$(wc -c "$param1" | awk '{print $1}')
	cmd=$?
	
	if [ "$cmd" -eq 0 ] && [ "$filesizedest" ] && [ "$filesizedest" -gt 0 ] ; then
		cursizedest=$(($filesizedest / $truncsize))
		if [ "$cursizedest" -gt 0 ] ; then
			cursizedest=$(($cursizedest - 1))
			dd if="$param1" of="$mytemp""/output.beingcompare" bs="$copyfilesize" count=2 skip="$cursizedest" > /dev/null 2>&1
		else
			dd if="$param1" of="$mytemp""/output.beingcompare" bs="$copyfilesize" count=1 skip="0" > /dev/null 2>&1
		fi
		
		kq=$(md5sum "$mytemp""/output.beingcompare" | awk '{ print $1 }')
		
	else
		kq="null"
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
declare -a mtime
declare -a hassamefile

declare -a names_remote
declare -a isfile_remote
declare -a filesize_remote
declare -a mtime_remote
declare -a hassamefile_remote

declare -a names_nt
declare -a filesize_nt
declare -a mtime_nt

declare -a names_remote_nt
declare -a filesize_remote_nt
declare -a mtime_remote_nt
declare -a isselected_remote_nt

found=0
count=0
mtime_temp=""

if [ -f "$memtemp""/""$param1" ] ; then

	while IFS=/ read beforeslash afterslash_1 afterslash_2 afterslash_3 afterslash_4
	do
		names[$count]="$afterslash_1"
		isfile[$count]="$afterslash_2"
		filesize[$count]="$afterslash_3"
		mtime[$count]="$afterslash_4"
		hassamefile[$count]=0
		count=$(($count + 1))
	done < "$memtemp""/""$param1"

	#len=${#names[@]}
	rm "$memtemp"/"$param3"
	touch "$memtemp"/"$param3"
	
	
	count=0

	for pathname in "$param2"/*; do
		
		if [ ! -d "$pathname" ] ; then 
			names_remote[$count]=$(basename "$pathname")
			hassamefile_remote[$count]=0
			
			isfile_remote[$count]="f"
			filesize_remote[$count]=$(wc -c "$pathname" | awk '{print $1}')
			mtime_temp=$(stat "$pathname" --printf='%y\n')
			mtime_remote[$count]=$(date +'%s' -d "$mtime_temp")
			#printf "%s/%s/%s/%s/%s\n" "$pathname" "f" "${filesize_remote[$count]}" "${headmd5sum_remote[$count]}" "${tailmd5sum_remote[$count]}" >> "$memtemp""/""$param3"
			
			count=$(($count + 1))
		fi

	done


	count=0
	for i in "${!names[@]}" ; do
		found=0
		for j in "${!names_remote[@]}" ; do
			#echo "herererererererererer-----""${names[$i]}""-------""${names_remote[$j]}"
			if [ "${isfile[$i]}" == "f" ] && [ "${names[$i]}" == "${names_remote[$j]}" ] ; then
					
					hassamefile[$i]=1
					hassamefile_remote[$j]=1
					if [ "${mtime[$i]}" == "${mtime_remote[$j]}" ] && [ "${filesize[$i]}" == "${filesize_remote[$j]}" ] ; then
						printf "./%s/1/%s/0/0\n" "${names[$i]}" "${names_remote[$j]}" >> "$memtemp""/""$param3"
					else
						printf "./%s/0/%s/%s/%s\n" "${names[$i]}" "${names_remote[$j]}" "${filesize_remote[$j]}" "${mtime_remote[$j]}" >> "$memtemp""/""$param3"
					fi
					count=1
					found=1
					break
			fi
		done

		#if [ "$found" -eq 1 ] ; then
		#	echo "found"
		#fi
		
	done


	#echo '------------------------file remains in local side------------------------------' >> "$memtemp""/""$param3"

	count=0
	for i in "${!hassamefile[@]}"
	do
		if [ "${hassamefile[$i]}" -eq 0 ] && [ "${isfile[$i]}" == "f" ] ; then
			names_nt[$count]="${names[$i]}"
			filesize_nt[$count]="${filesize[$i]}"
			mtime_nt[$count]="${mtime[$i]}"
			#printf "%s/%s/%s/%s\n" "${names_nt[$count]}" "${filesize_nt[$count]}" "${headmd5sum_nt[$count]}" "${tailmd5sum_nt[$count]}" >> "$memtemp""/""$param3"
			count=$(($count + 1))
		fi
		
	done


	#echo "$count"'------------------------file remains in remote side------------------------------' >> "$memtemp""/""$param3"

	count=0
	for i in "${!hassamefile_remote[@]}"
	do
		if [ "${hassamefile_remote[$i]}" -eq 0 ] && [ "${isfile_remote[$i]}" == "f" ] ; then
			names_remote_nt[$count]="${names_remote[$i]}"
			isselected_remote_nt[$count]=0
			filesize_remote_nt[$count]="${filesize_remote[$i]}"
			mtime_remote_nt[$count]="${mtime_remote[$i]}"
			#printf "%s/%s/%s/%s\n" "${names_remote_nt[$count]}" "${filesize_remote_nt[$count]}" "${headmd5sum_remote_nt[$count]}" "${tailmd5sum_remote_nt[$count]}" >> "$memtemp""/""$param3"
			count=$(($count + 1))
		fi
		
	done

	#echo "$count"'------------------------file so sanh------------------------------' >> "$memtemp""/""$param3"
	#so sanh
	for i in "${!names_nt[@]}"
	do
		count=0
		for j in "${!names_remote_nt[@]}"
		do
			if [ "${isselected_remote_nt[$j]}" -eq 0 ] && [ "${mtime_nt[$i]}" == "${mtime_remote_nt[$j]}" ] && [ "${filesize_nt[$i]}" == "${filesize_remote_nt[$j]}" ] ; then
				printf "./%s/2/%s/0/0\n" "${names_nt[$i]}" "${names_remote_nt[$j]}" >> "$memtemp""/""$param3"
				mv "$param2""/""${names_remote_nt[$j]}" "$param2""/""${names_nt[$i]}"
				isselected_remote_nt[$j]=1
				count=1
				break
			fi
		done
		
		#if [ "$count" -eq 0 ] ; then
		#	echo 'do some thing'
		#fi
		
	done

	#echo '------------------------file bi xoa------------------------------' >> "$memtemp""/""$param3"
	#xoa nhung file con lai
	for i in "${!names_remote_nt[@]}"
	do
		if [ "${isselected_remote_nt[$i]}" -eq 0 ] ; then
			rm "$param2""/""${names_remote_nt[$i]}"
			printf "./null/3/%s/0/0\n" "${names_remote_nt[$j]}" >> "$memtemp""/""$param3"
		fi
	done

	rm "$memtemp""/""$param1"
	echo './' >> "$memtemp""/""$param3"
fi
