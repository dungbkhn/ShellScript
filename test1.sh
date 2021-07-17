#!/bin/bash

shopt -s dotglob
shopt -s nullglob

dir_ori=/home/dungnt/ShellScript/dirtest1
dir_dest=/home/backup/storageBackup

appdir_local=/home/dungnt/ShellScript/sshsyncapp
appdir_remote=/home/backup

memtemp_local="$appdir_local"/.temp
memtemp_remote="$appdir_remote"/.temp

#them vao
compare_listdir_inremote=comparelistdir_remote.sh
#them vao
outputdirforcmp_inremote=outputdir_inremote.txt

compare_listfile_inremote=comparelistfile_remote.sh
getmd5hash_inremote=getmd5hash_inremote.sh
truncatefile_inremote=truncatefile_inremote.sh
catfile_inremote=catfile_inremote.sh
dir_contains_uploadfiles="$appdir_local"/remotefiles

destipv6addr="backup@2405:4803:fe18:bc50::e"
destipv6addr_scp="backup@[2405:4803:fe18:bc50::e]"

filepubkey=/home/dungnt/.ssh/id_rsa_backup_58
logtimedir_remote=/home/dungnt/MyDisk_With_FTP/logtime
logtimefile=logtimefile.txt
#file mang thong tin ds file trong dir --> up len de so sanh
outputfileforcmp_inremote=outputfile_inremote.txt


uploadmd5hashfile=md5hashfile_fromlocal.txt


sleeptime=5
#for PRINTING
prt=1


#----------------------------------------TOOLS-------------------------------------

myecho(){
	local param=$1
	
	if [ $prt -eq 1 ]; then
			echo "$param"
	fi
}

myprintf(){
	local param1=$1
	local param2=$2
	
	if [ $prt -eq 1 ]; then
			printf "$param1"": %s\n" "$param2"
	fi
}

#-------------------------------CHECK NETWORK-------------------------------------

check_network(){
	local state
	local cmd
	
	#trang thai mac dinh=1:ko co mang
	state=1
	
	ping -c 1 -W 1 -4 google.com
	cmd=$?
	
	if [ "$cmd" -eq 0 ] ; then
		#co mang
		state=0
	fi 
	
	if [ "$state" -eq 0 ] ; then
	
		ping -c 1 -W 1 -4 vnexpress.net
		cmd=$?

		if [ "$cmd" -eq 0 ] ; then
			#co mang
			state=0
		fi 
		
	fi

	#0: co mang
	#1: ko co mang
	return "$state"
}

#------------------------------ VERIFY ACTIVE USER --------------------------------
verify_logged() {
	#mac dinh la ko thay active user 
	local kq
	local result
	local cmd
	local line
	local value
	local curtime
	local delaytime
	
	kq=1
	
	if [ -f "$filepubkey" ] ; then
	
		result=$(ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$filepubkey" "$destipv6addr" "tail ${logtimedir_remote}/${logtimefile}")
		cmd=$?
		echo "$result"
		
		if [ "$cmd" -eq 0 ] ; then
				#echo 'tim thay' $logtimefile
				if [ "$result" ] ; then
					curtime=$(($(date +%s%N)/1000000))
					#printf 'curtime:%s\n' "$curtime"
					value=$(echo "${result##*$'\n'}")
					printf 'value:%s\n' "$value"
					delaytime=$(( ( $curtime - $value ) / 60000 ))
					printf 'delaytime:%s\n' "$delaytime"" minutes"
					if [ "$delaytime" -gt 6 ] ; then
						#ko thay active web user
						kq=0
					else
						#tim thay co active web user
						kq=255
					fi
				fi
		fi
	fi

	#1: run function fail
	#0: no active web user found
	#255: active web user found
	return "$kq"
}

#------------------------------ FIND SAME DIR --------------------------------

find_list_same_dirs () {
	local param1=$1
	local param2=$2
	local count
	local workingdir=$(pwd)
	local cmd
	local cmd1
	local cmd2
	local cmd3
	local result
	local pathname
	local subpathname
	local filesize
	local listfiles="listdirsforcmp.txt"
	local outputdir_inremote="$outputdirforcmp_inremote"
	local loopforcount
	
	rm "$memtemp_local"/*

	cd "$param1"/
	
	touch "$memtemp_local"/"$listfiles"
	
	for pathname in ./* ; do
		if [ -d "$pathname" ] ; then 
			printf "%s/b/%s/%s\n" "$pathname" "d" "0" >> "$memtemp_local"/"$listfiles"
			count=0
			cd "$param1"/"$pathname"
			for subpathname in ./* ; do
				if [ -d "$subpathname" ] ; then 
					printf "%s/n/%s/%s\n" "$subpathname" "d" "1" >> "$memtemp_local"/"$listfiles"
				else
					printf "%s/n/%s/%s\n" "$subpathname" "f" "1" >> "$memtemp_local"/"$listfiles"
				fi
				count=$(($count + 1))
				if [ "$count" -eq 5 ] ; then
					break
				fi
			done
			printf "%s/e/%s/%s\n" "$pathname" "d" "0" >> "$memtemp_local"/"$listfiles"		
			cd "$param1"/
		fi
		
	done
	
	
	cd "$workingdir"/
	
	result=$(scp -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$filepubkey" -p "$memtemp_local"/"$listfiles" "$destipv6addr_scp":"$memtemp_remote"/)
	cmd1=$?
	myprintf "scp 1 listfile" "$cmd1"
			
	result=$(scp -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$filepubkey" -p "$dir_contains_uploadfiles"/"$compare_listdir_inremote" "$destipv6addr_scp":"$memtemp_remote"/)
	cmd2=$?
	myprintf "scp 1 shellfile" "$cmd2"

	result=$(ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$filepubkey" "$destipv6addr" "rm ${memtemp_remote}/${outputdir_inremote}")
	cmd3=$?
	
	myprintf "ssh remove old outputfile" "$cmd3"
	pathname=$(echo "$param2" | tr -d '\n' | xxd -pu -c 1000000)
	
	if [ "$cmd1" -eq 0 ] && [ "$cmd2" -eq 0 ] && [ "$cmd3" -ne 255 ] ; then
		for (( loopforcount=0; loopforcount<21; loopforcount+=1 ));
		do
			result=$(ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$filepubkey" "$destipv6addr" "bash ${memtemp_remote}/${compare_listdir_inremote} ${listfiles} ${pathname} ${outputdir_inremote}")
			cmd=$?
			myprintf "ssh generate new outputdir" "$cmd"
			if [ "$cmd" -eq 0 ] ; then
				break
			else
				sleep 1
			fi
		done
		
		if [ "$cmd" -eq 0 ] ; then
			result=$(scp -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$filepubkey" -p "$destipv6addr_scp":"$memtemp_remote"/"$outputdir_inremote" "$memtemp_local"/)
			cmd=$?
			myprintf "scp getback outputdir" "$cmd"
		fi
	fi
}

find_list_same_dirs "/home/dungnt/ShellScript/tối quá" "/home/backup/so sánh thư mục"
