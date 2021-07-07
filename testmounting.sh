#!/bin/bash

shopt -s dotglob
shopt -s nullglob

logfile=/home/dungnt/MyLog/logmounting.txt
mainlocation=/var/res/share
slavelocation=/var/res/backup
dev1=sda1
dev2=sdb1
dev3=sdc1

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

countmounting=0
hasslave=0

findmainlocation=$(df | grep "$mainlocation")

echo "$findmainlocation"

if [ "$findmainlocation" ] ; then
	countmounting=$(($countmounting + 1))
fi

findslavelocation=$(df | grep "$slavelocation")

echo "$findslavelocation"

if [ "$findslavelocation" ] ; then
	countmounting=$(($countmounting + 1))
	hasslave=$(($hasslave + 1))
fi

echo "countmounting=""$countmounting"
echo "hasslave=""$hasslave"
echo '-----------------------------------------------'

## declare an array variable
declare -a myarr=("$dev1" "$dev2" "$dev3")
declare -a myspace=(0 0 0)
declare -a mytype=(0 0 0)
declare -a myuuid=("" "" "")

firstmax=0
secondmax=0
firstmaxuuid=""
secondmaxuuid=""
firstname=""
secondname=""

needreboot=0

echo '---------------------Begin-------------------' > "$logfile"

## now loop through the above array
for i in "${!myarr[@]}"
do
   # echo "$i"
   # or do whatever with"individual element of the array
   if [ "${myarr[$i]}"  ] ; then
		echo "${myarr[$i]}" >> "$logfile"
		disks_space "${myarr[$i]}"
		myspace[$i]=$?
		check_disks_type "${myarr[$i]}" "exfat"
		mytype[$i]=$?
   
		echo "exfat(1-yes):""${mytype[$i]}" >> "$logfile"
		echo "space(GB):""${myspace[$i]}" >> "$logfile"

		if [ "${mytype[$i]}" -eq 0 ] && [ "${myspace[$i]}" -gt 0 ] ; then
			umount /dev/"${myarr[$i]}"
			/sbin/mkfs.exfat /dev/"${myarr[$i]}"
			needreboot=1
			cp /etc/fstab.save /etc/fstab
		else
			echo "type is exfat (1) or space is equal to 0, so do not need format in exfat fs"
		fi
   		
		myuuid[$i]=$(get_disks_uuid "${myarr[$i]}")
		echo "${myuuid[$i]}" >> "$logfile"

		if [ "${mytype[$i]}" -eq 1 ] ; then
			if [ "${myspace[$i]}" -ge "$firstmax" ] ; then
				secondmax=$firstmax
				secondmaxuuid="$firstmaxuuid"
				secondname="$firstname"
				firstmax=${myspace[$i]}
				firstmaxuuid="${myuuid[$i]}"
				firstname="${myarr[$i]}"
			elif [ "${myspace[$i]}" -gt "$secondmax" ] ; then
				secondmax=${myspace[$i]}
                                secondmaxuuid="${myuuid[$i]}"
                                secondname="${myarr[$i]}"
			fi
		fi

		
		echo '------------------------------' >> "$logfile"
   fi
done

if [ "$needreboot" -eq 1 ] ; then
	sleep 30
	/sbin/reboot
fi


countdev=0

echo "firsmax=""$firstmax"
echo "$firstmaxuuid"
echo "$firstname"
echo "secondmax=""$secondmax"
echo "$secondmaxuuid"
echo "$secondname"

if [ "$firstmax" -gt 0 ] ; then
	countdev=$(($countdev + 1))
	if [ "$secondmax" -gt 0 ] ; then
		countdev=$(($countdev + 1))
	fi
fi

echo "countdev=""$countdev"

printf "%s\n" "countdev=""$countdev" >> "$logfile"
printf "%s\n" "countmounting=""$countmounting" >> "$logfile"
printf "%s\n" "hasslave=""$hasslave" >> "$logfile"
  
if [ "$countdev" -ne "$countmounting" ] && [ "$countdev" -gt 0 ] ; then
	cp /etc/fstab.save /etc/fstab
	if [ "$countdev" -eq 1 ] ; then
		printf "%s\n" "$firstmaxuuid"" ""$mainlocation"" ""auto uid=store,gid=restriction,nodev,nofail,x-gvfs-show 0 0" >> /etc/fstab 
		printf "n1:%s\n" "$firstmaxuuid"" ""$mainlocation"" ""auto uid=store,gid=restriction" >> "$logfile"
		sleep 45
		/sbin/reboot
	else
		printf "%s\n" "$secondmaxuuid"" ""$mainlocation"" ""auto uid=store,gid=restriction,nodev,nofail,x-gvfs-show 0 0" >> /etc/fstab
		printf "%s\n" "$firstmaxuuid"" ""$slavelocation"" ""auto uid=backup,gid=backup,nodev,nofail,x-gvfs-show 0 0" >> /etc/fstab
		printf "n2:%s\n" "$secondmaxuuid"" ""$mainlocation"" ""auto uid=store,gid=restriction" >> "$logfile"
		sleep 45
		/sbin/reboot
	fi
fi

if [ "$countdev" -eq "$countmounting" ] && [ "$countmounting" -eq 1 ] && [ "$hasslave" -gt 0 ] ; then
	cp /etc/fstab.save /etc/fstab
	printf "%s\n" "$firstmaxuuid"" ""$mainlocation"" ""auto uid=store,gid=restriction,nodev,nofail,x-gvfs-show 0 0" >> /etc/fstab
	printf "n3:%s\n" "$firstmaxuuid"" ""$mainlocation"" ""auto uid=store,gid=restriction" >> "$logfile"	
	sleep 45
	/sbin/reboot
fi

echo "mounting process successful!"
printf "%s" "###ok###" >> "$logfile"
