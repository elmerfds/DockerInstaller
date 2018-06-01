#!/bin/bash -e
#Docker Installer
#author: elmerfdz
version=v0.0.15

#Script Requirements
prereqname=('Curl' )
prereq=('curl')


#Script config variables
tzone=$(cat /etc/timezone)
uid=$(id -u $(logname))
ugp=$(cut -d: -f3 < <(getent group docker))
ubu_code=$(cut -d: -f2 < <(lsb_release -c)| xargs)
docker_data='/opt/docker/data'
docker_init='/opt/docker/init'

#Modules

# Script Requirements
script_prereq()
    {
                echo
                echo -e "\e[1;36m> Updating apt repositories...\e[0m"
		echo
		apt-get update	    
                echo
		for ((i=0; i < "${#prereqname[@]}"; i++)) 
		do
		    echo -e "\e[1;36m> Installing ${prereqname[$i]}...\e[0m"
		    echo
		    apt-get -y install ${prereq[$i]}
		    echo
		
		done
		echo


    } 

# Docker Installation
docker_install()
	{
        echo "- Your choice: 1. Docker and Docker Compose Install"
        #add docker source
        touch /etc/apt/sources.list.d/docker.list
		if [ $ubu_code = "bionic" ]
		then
        branch=edge

        elif [ $ubu_code = "artful" ]
        then
        branch=stable

        elif [ $ubu_code = "xenial" ]
        then
        branch=stable
        fi

        echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $ubu_code $branch" >> /etc/apt/sources.list.d/docker.list
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

        #Install docker
        apt update
        apt install docker-ce -y
        curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-`uname -s`-`uname -m` -o /usr/bin/docker-compose

        ##Configure docker permissions
        chmod +x /usr/bin/docker-compose
        usermod -aG docker ${USER}
		echo "- Docker and Docker Compose Installed"
        
        #install maintainer
        touch ./inst_temp

        sleep 3s
		chmod +x $BASH_SOURCE
		exec ./installer.sh
	}

# Docker Variables and Folders
docker_env_set()
	{
        echo -e "\e[1;36m> Environment Section...\e[0m"
        echo "PUID=$uid" >> /etc/environment
        echo "PGID=$ugp" >> /etc/environment
        echo "TZ="$tzone"" >> /etc/environment
        echo "USERDIR=/home/$(logname)" >> /etc/environment
        echo "ROOTDIR="/opt/docker"" >> /etc/environment
        echo "DATADIR="/opt/docker/data"" >> /etc/environment

	    if [ ! -d "$docker_data" ]; then
		mkdir -p $docker_data
		fi

	    if [ ! -d "$docker_init" ]; then
		mkdir -p $docker_init
		fi
        rm -rf ./inst_temp
        echo -e "\e[1;36m> Docker variables set...\e[0m"
    }

# Docker Installation
test_env_set()
	{
        echo "timezone = $tzone"
        echo "user = $uid"
        echo "docker group = $ugp"
        echo "Ubuntu Codename = $ubu_code"
        echo "branch_test = $branch"
        read
 
	}



show_menus() 
	{
	    if [ -e "./inst_a" ]; then
        docker_env_set
        sleep 3s
        clear
		fi
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		echo -e " 	  \e[1;36mDocker- INSTALLER $version  \e[0m"
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		echo " 1. Install Docker + Docker Compose  " 
		echo " 2. Install Docker/Docker Compose + Containers [Coming Soon] "
        echo " 7. Quit		 "
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		echo
		printf "\e[1;36m> Enter your choice: \e[0m"
	}
read_options(){
		read -r options

		case $options in
	 	"1")
			echo "- Your choice: 1. Install Docker & Docker Compose"
            script_prereq
            docker_install
                	echo -e "\e[1;36m> \e[0mPress any key to return to menu..."
			read
		;;

	 	"2")
			echo "- Your choice 2: Install Docker/Docker Compose + Containers [coming soon]"
           
                	echo -e "\e[1;36m> \e[0mPress any key to return to menu..."
			read
		;; 

	 	"3")
			echo "- Your choice 3: Testing variables"
			 test_env_set
                	echo -e "\e[1;36m> \e[0mPress any key to return to menu..."
			read
		;;
        
	 	"4")
			echo "- Your choice 4: Organizr Complete Install (Org + Requirements) "
	        	orgreq_mod
			echo -e "\e[1;36m> \e[0mPress any key to continue with Organizr + Nginx site config"
			read
                	echo -e "\e[1;36m> \e[0mPress any key to return to menu..."
			read
		;;

	 	"5")
	        	oui_updater_mod
		;;

		"6")
			while true 
			do
			clear
			uti_menus
			uti_options
			done
		;;

		"7")
			exit 0
		;;


	      	esac
	     }

while true 
do
	clear
	show_menus
	read_options
done