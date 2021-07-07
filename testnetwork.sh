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

#printf "Begin\n" > /home/dungnt/routerip.txt

while true ; do

	printf "#-----------------Begin-------------------#\n" > /home/dungnt/MyLog/routerip.txt
	
	sleep 1m
	
	#trang thai mac dinh=1:ko co mang
	state=1
	
	ping -c 1 -W 1 -4 google.com
	cmd=$?
	
	if [ "$cmd" -eq 0 ] ; then
		#co mang
		diff /etc/network/interfaces /etc/network/interfaces.auto
		cmd=$?

		printf "ping0ok\n" >> /home/dungnt/MyLog/routerip.txt 
		echo "ping0ok"

		if [ "$cmd" -eq 0 ] ; then
			#hai file giong het nhau  ----> trang thai 2
			state=2
		else
			state=3
		fi
	fi 
	
	for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40
	do
	    #echo "Welcome $i times"

		sleep 1
		
		if [ "$state" -eq 1 ] ; then
		
			ping -c 1 -W 1 -4 vnexpress.net
			cmd=$?

			if [ "$cmd" -eq 0 ] ; then
				#co mang
				diff /etc/network/interfaces /etc/network/interfaces.auto
				cmd=$?

				printf "ping%sok\n" "$i" >> /home/dungnt/MyLog/routerip.txt
				echo "ping""$i""ok"

				if [ "$cmd" -eq 0 ] ; then
					#hai file giong het nhau  ----> trang thai 2
					state=2
				else
					state=3
				fi
			fi 
			
		fi

		
		sleep 1
		
		if [ "$state" -eq 1 ] ; then
		
			ping -c 1 -W 1 -4 google.com
			cmd=$?

					
			if [ "$cmd" -eq 0 ] ; then
				#co mang
				diff /etc/network/interfaces /etc/network/interfaces.auto
				cmd=$?

				printf "ping%sok\n" "$i" >> /home/dungnt/MyLog/routerip.txt
				echo "ping""$i""ok"

				if [ "$cmd" -eq 0 ] ; then
					#hai file giong het nhau  ----> trang thai 2
					state=2
				else
					state=3
				fi
			fi 
			
		fi

	done
	
	sleep 2
	
	#mat network
	if [ "$state" -eq 1 ] ; then
		#trang thai 1
		#echo 'mat mang
		printf "%s\n" "trang thai 1" >> /home/dungnt/MyLog/routerip.txt
		echo "trangthai1"
		cp /etc/network/interfaces.auto /etc/network/interfaces
		sleep 30
		/sbin/reboot
	elif [ "$state" -eq 2 ] ; then
		#trang thai 2
		routerip=$(/sbin/ifconfig | grep 'inet6' | grep 'scopeid 0x0<global>' | awk '{print $2}')
		result=$(get_router_baseIP "$routerip")
		
		printf "#ipv6 manual config\n" >> /etc/network/interfaces
		printf "auto eth0\n" >> /etc/network/interfaces
		printf "iface eth0 inet6 static\n" >> /etc/network/interfaces
		printf "address ""$result""::e\n" >> /etc/network/interfaces
		printf "netmask 64\n" >> /etc/network/interfaces
		printf "gateway ""$result""::0\n" >> /etc/network/interfaces
		printf "######" >> /etc/network/interfaces
		
		printf "%s\n" "trang thai 2" >> /home/dungnt/MyLog/routerip.txt
		echo "trangthai2"

		sleep 30
		/sbin/reboot
	else
		#trang thai 3
		routerip=$(/sbin/ifconfig | grep 'inet6' | grep 'scopeid 0x0<global>' | awk '{print $2}')
		result=$(get_router_baseIP "$routerip")
		cp /etc/network/interfaces.auto /etc/network/interfaces.being
		
		printf "#ipv6 manual config\n" >> /etc/network/interfaces.being
		printf "auto eth0\n" >> /etc/network/interfaces.being
		printf "iface eth0 inet6 static\n" >> /etc/network/interfaces.being
		printf "address ""$result""::e\n" >> /etc/network/interfaces.being
		printf "netmask 64\n" >> /etc/network/interfaces.being
		printf "gateway ""$result""::0\n" >> /etc/network/interfaces.being
		printf "######" >> /etc/network/interfaces.being
		
		diff /etc/network/interfaces /etc/network/interfaces.being
		cmd=$?
		
		if [ "$cmd" -eq 0 ] ; then
			#hai file giong het nhau  ----> trang thai 3.0
			printf "%s\n" "trang thai 3.0, moi thu ok" >> /home/dungnt/MyLog/routerip.txt
			echo "trangthai3.0"
			rm /etc/network/interfaces.being
		else
			#trang thai 3.1
			printf "%s\n" "trang thai 3.1, ipv6 chua chuan" >> /home/dungnt/MyLog/routerip.txt
			echo "trangthai3.1"
			mv /etc/network/interfaces.being /etc/network/interfaces
			sleep 30
			/sbin/reboot
		fi
	fi
	
	echo "sleep 15m"
	sleep 15m
done


