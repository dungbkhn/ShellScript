#!/bin/bash

get_router_baseIP(){
	local IFS
	local strarr
	local len
	local firstelement
	local baseip
	
	
	# Set comma as delimiter
	IFS=':'

	#Read the split words into an array based on comma delimiter
	read -a strarr <<< "$1"

	len=${#strarr[@]}

	len=$(( $len - 1 ))

	firstelement=$(echo "${strarr[0]}" | xargs)

	baseip="$firstelement"":""${strarr[1]}"":""${strarr[2]}"":""${strarr[3]}"
	
	echo "$baseip"
}

#------------------------------------ MAIN ---------------------------------

file1=/home/dungnt/MyLog/routerip1.txt
file2=/home/dungnt/MyLog/routerip2.txt
filesizeforswich=5000

while true ; do
	hasoldfile=0
	oldfile=null
	mainfile=$file1
	haslongsleep=0
	numberreset=0

	if [ -f "$file1" ] ; then
		filesize1=$(wc -c "$file1" | awk '{print $1}')
		mtime1=$(stat "$file1" --printf='%y\n')
		mtime1=$(date +'%s' -d "$mtime1")
	else
		filesize1=0
	fi

	if [ -f "$file2" ] ; then
		filesize2=$(wc -c "$file2" | awk '{print $1}')
		mtime2=$(stat "$file2" --printf='%y\n')
		mtime2=$(date +'%s' -d "$mtime2")
	else
		filesize2=0
	fi

	if [ "$filesize1" -eq 0 ] && [ "$filesize2" -eq 0 ] ; then
		mainfile=$file1
		rm "$file1" > /dev/null
		rm "$file2" > /dev/null
		touch "$file1"
		hasoldfile=0
	elif [ "$filesize2" -eq 0 ] ; then
		rm "$file2" > /dev/null
		hasoldfile=1
		if [ "$filesize1" -gt "$filesizeforswich" ] ; then
			mainfile=$file2
			touch "$file2"
		else
			mainfile=$file1
		fi
	elif [ "$filesize1" -eq 0 ] ; then
		mainfile=$file1
		rm "$file1" > /dev/null
		rm "$file2" > /dev/null
		touch "$file1"
		hasoldfile=0
	else
		if [ "$filesize1" -gt "$filesizeforswich" ] && [ "$filesize2" -gt "$filesizeforswich" ] ; then
			if [ "$mtime1" -gt "$mtime2" ] ; then
				#dang write vao file 1, chon file 2
				hasoldfile=1
				rm "$file2" > /dev/null
				touch "$file2"
				mainfile=$file2
			else
				#dang write vao file 2, chon file 1
				hasoldfile=2
				rm "$file1" > /dev/null
				touch "$file1"
				mainfile=$file1
			fi
		elif [ "$filesize1" -lt "$filesizeforswich" ] && [ "$filesize2" -gt "$filesizeforswich" ] ; then
			mainfile=$file1
			hasoldfile=1
		elif [ "$filesize1" -gt "$filesizeforswich" ] && [ "$filesize2" -lt "$filesizeforswich" ] ; then
			mainfile=$file2
			hasoldfile=2
		elif [ "$filesize1" -lt "$filesizeforswich" ] && [ "$filesize2" -lt "$filesizeforswich" ] ; then
			mainfile=$file1
			rm "$file1" > /dev/null
			rm "$file2" > /dev/null
			touch "$file1"
			hasoldfile=0
		fi
	fi
	
	if [ "$hasoldfile" -ne 0 ] ; then
		#read old file
		if [ "$hasoldfile" -eq 1 ] ; then
			oldfile=$file1
		elif [ "$hasoldfile" -eq 2 ] ; then
			oldfile=$file2
		fi
		
		count=0
		while IFS= read -r line
		do
			if [ "$line" == "######" ] ; then
				count=$(( $count + 1 ))
			elif [ "$count" -eq 1 ] ; then
				haslongsleep="$line"
				count=$(( $count + 1 ))
			elif [ "$count" -eq 2 ] ; then
				numberreset="$line"
				count=$(( $count + 1 ))
			fi
		done <<< "$(tail -n 3 ${oldfile})"
		
		if [ "$count" -eq 0 ] ; then
			mainfile=$file1
			rm "$file1" > /dev/null
			rm "$file2" > /dev/null
			touch "$file1"
			oldfile=null
			hasoldfile=0
		fi
	fi
	
	printf "#-----------------Begin-------------------#\n" >> "$mainfile"
	
	echo "mainfile:""$mainfile" >> "$mainfile"
	echo "oldfile:""$oldfile" >> "$mainfile"
	echo "haslongsleep:""$haslongsleep" >> "$mainfile"
	echo "numberreset:""$numberreset" >> "$mainfile"
	
	echo "mainfile:""$mainfile"
	echo "oldfile:""$oldfile"
	echo "haslongsleep:""$haslongsleep"
	echo "numberreset:""$numberreset"
	
	printf "#-----------------Wait 50s for mouting-------------------#\n" >> "$mainfile"
	
	sleep 50
	
	printf "#-----------------OK, Try Ping -------------------#\n" >> "$mainfile"
	
	#trang thai mac dinh=1:ko co mang
	state=1
	
	ping -c 1 -W 1 -6 google.com > /dev/null
	cmd=$?
	
	if [ "$cmd" -eq 0 ] ; then
		#co mang
		diff /etc/network/interfaces /etc/network/interfaces.auto > /dev/null
		cmd=$?

		printf "ping0 ok\n" >> "$mainfile"
		echo "ping0 ok"

		if [ "$cmd" -eq 0 ] ; then
			#hai file giong het nhau  ----> trang thai 3
			state=3
		else
			state=2
		fi
	else
		printf "ping0 fail\n" >> "$mainfile"
	fi 
	
	ping -c 1 -W 1 -6 vnexpress.net > /dev/null
	cmd=$?
	
	if [ "$cmd" -eq 0 ] ; then
		#co mang
		diff /etc/network/interfaces /etc/network/interfaces.auto > /dev/null
		cmd=$?

		printf "ping1 ok\n" >> "$mainfile"
		echo "ping1 ok"

		if [ "$cmd" -eq 0 ] ; then
			#hai file giong het nhau  ----> trang thai 3
			state=3
		else
			state=2
		fi
	else
		printf "ping1 fail\n" >> "$mainfile"
	fi 
	
	if [ "$state" -eq 1 ] ; then
		loopforcount=0
		for (( loopforcount=2; loopforcount<25; loopforcount+=1 ));
		do
			#echo "Welcome $i times"

			sleep 1
			
			ping -c 1 -W 1 -6 vnexpress.net > /dev/null
			cmd=$?

			if [ "$cmd" -eq 0 ] ; then
				#co mang
				diff /etc/network/interfaces /etc/network/interfaces.auto > /dev/null
				cmd=$?

				#printf "ping%s ok\n" "$loopforcount" >> "$mainfile"
				echo "ping""$loopforcount"" ok"

				if [ "$cmd" -eq 0 ] ; then
					#hai file giong het nhau  ----> trang thai 3
					state=3
				else
					state=2
				fi
				
				break
			
			fi 
			
			sleep 1
						
			ping -c 1 -W 1 -6 google.com > /dev/null
			cmd=$?

			if [ "$cmd" -eq 0 ] ; then
				#co mang
				diff /etc/network/interfaces /etc/network/interfaces.auto > /dev/null
				cmd=$?

				#printf "ping%s ok\n" "$loopforcount" >> "$mainfile"
				echo "ping""$loopforcount"" ok"

				if [ "$cmd" -eq 0 ] ; then
					#hai file giong het nhau  ----> trang thai 3
					state=3
				else
					state=2
				fi
				
				break
			
			fi 
		done
	fi
	
	printf "state:%s\n" "$state" >> "$mainfile"
	
	sleep 2
	
	#mat network
	if [ "$state" -eq 1 ] && [ "$numberreset" -lt 3 ] ; then
		#trang thai 1
		#mat mang
		printf "%s\n" "trang thai 1" >> "$mainfile"
		echo "trangthai1"
		cp /etc/network/interfaces.auto /etc/network/interfaces
		printf "%s\n" "trang thai 1 - need reset" >> "$mainfile"
		echo "trang thai 1"
		echo "######" >> "$mainfile"
		#longsleep no
		echo "0" >> "$mainfile"
		#numberreset ++
		numberreset=$(( $numberreset + 1 ))
		echo "$numberreset" >> "$mainfile"
		echo "trang thai 1 - reset"
		sleep 15
		systemctl restart networking > /dev/null
		/sbin/ifdown eth0 && /sbin/ifup eth0 > /dev/null
	elif [ "$state" -eq 2 ] && [ "$numberreset" -lt 3 ] ; then
		#trang thai 2
		#co mang nhung file interfaces chua dung
		printf "%s\n" "trang thai 2" >> "$mainfile"
		echo "trangthai2"
		cp /etc/network/interfaces.auto /etc/network/interfaces
		printf "%s\n" "trang thai 2 - need reset" >> "$mainfile"
		echo "trang thai 2"
		echo "######" >> "$mainfile"
		#longsleep no
		echo "0" >> "$mainfile"
		#numberreset ++
		numberreset=$(( $numberreset + 1 ))
		echo "$numberreset" >> "$mainfile"
		echo "trang thai 2 - reset"
		sleep 15
		systemctl restart networking > /dev/null
		/sbin/ifdown eth0 && /sbin/ifup eth0 > /dev/null
	elif [ "$state" -eq 3 ] && [ "$numberreset" -lt 3 ] ; then
		#trang thai 3
		routerip=$(ifconfig | grep 'inet6' | grep 'scopeid 0x0<global>' | awk '{print $2}')
		result=$(get_router_baseIP "$routerip")
		#can gui IPV6 len server
		echo "myip ""$routerip"
		printf "%s\n" "trang thai 3 - ok" >> "$mainfile"
		echo "######" >> "$mainfile"
		#longsleep yes
		echo "1" >> "$mainfile"
		#numberreset no
		echo "0" >> "$mainfile"
		echo "trang thai 3 - ok"
		sleep 20m
	else
		printf "%s\n" "numberreset qua lon" >> "$mainfile"
		printf "%s\n" "sleep 15m" >> "$mainfile"
		echo "######" >> "$mainfile"
		#longsleep yes
		echo "1" >> "$mainfile"
		#numberreset no
		echo "0" >> "$mainfile"
		echo "sleep 20m"
		sleep 20m
	fi

done


