#!/bin/bash

shopt -s dotglob
shopt -s nullglob

disks_space() {
	local param=$1
	local kq
	local num
	
    #! df -P | awk '{print $5}' | grep -Fqx '100%'
    kq=$(lsblk | grep "$param" | awk '{print $4}')
    #kq=${kq%G}
    #NUMBER=$(echo "$kq" | grep -o -E '[0-9]+')
    if [ "$kq" ] ; then		
		num=$(echo $kq | sed -r 's/^([^.]+).*$/\1/; s/^[^0-9]*([0-9]+).*$/\1/')
	else
		num=0
	fi
	
    return "$num"
}

check_disks_type() {
	local param1=$1
	local param2=$2
	local kq
	local num
	
    kq=$(/sbin/blkid | grep "$param1" | grep "$param2")
    if [ "$kq" ] ; then		
		num=1
	else
		num=0
	fi
	
	#1: param2
	#0: other
    return "$num"
}

get_disks_uuid() {
	local param=$1
	local kq

	
    kq=$(/sbin/blkid | grep "$param" | awk '{for(i=2;i<=NF;i++){if($i~/^UUID=/){a=$i}} print a}')
	
	echo "$kq"
}

## declare an array variable
declare -a myarr=("$1" "$2" "$3")
declare -a myspace=(0 0 0)
declare -a mytype=(0 0 0)



## now loop through the above array
for i in "${!myarr[@]}"
do
   # echo "$i"
   # or do whatever with"individual element of the array
   if [ "${myarr[$i]}"  ] ; then
		echo "${myarr[$i]}"
		disks_space "${myarr[$i]}"
		myspace[$i]=$?
		check_disks_type "${myarr[$i]}" "exfat"
		mytype[$i]=$?
   
		echo "exfat(1-yes):""${mytype[$i]}"
		echo "space(GB):""${myspace[$i]}"

		if [ "${mytype[$i]}" -eq 0 ] && [ "${myspace[$i]}" -gt 0 ] ; then
			umount /dev/"${myarr[$i]}"
			mkfs.exfat /dev/"${myarr[$i]}"
		else
			echo "type is exfat (1) or space is equal to 0, so do not need format in exfat fs"
		fi
   
		echo $(get_disks_uuid "${myarr[$i]}")
		echo '------------------------------'
   fi
done


   


