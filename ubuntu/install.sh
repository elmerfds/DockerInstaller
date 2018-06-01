#!/bin/bash -e
#Docker Installer
#author: elmerfdz
version=v0.31.5

#Script Requirements
prereqname=('Curl' )
prereq=('curl')

#Default Container Names
container_name=('Portainer' 'Watchtower' 'PHPmyadmin' 'Mariadb' 'Organizr' 'Postgres' 'Guacamole')

#Script config variables
tzone=$(cat /etc/timezone)
uid=$(id -u $(logname))
ugp=$(cut -d: -f3 < <(getent group docker))
ubu_code=$(cut -d: -f2 < <(lsb_release -c)| xargs)
docker_dir='/opt/docker'
docker_data='/opt/docker/data'
docker_init='/opt/docker/init'
CURRENT_DIR=`dirname $0`

#Temp env variables 
export PUID=$uid
export PGID=$ugp
export TZ="$tzone"
export USERDIR="/home/$(logname)"
export ROOTDIR="/opt/docker"
export DATADIR="/opt/docker/data"
export MYSQL_ROOT_PASSWORD="changeMe!"

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

 # Script Requirements
default_container_names()
    {
        echo
        echo -e "\e[1;36m> Installing default containers:\e[0m"
        echo
		for ((i=0; i < "${#container_name[@]}"; i++)) 
		do
		    echo -e "\e[1;36m$i. ${container_name[$i]}\e[0m"
		done
		echo
    }    

# Docker Installation
docker_install()
	{
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

        #Reloading Shell, to get docker group id
        shell_reload
	}

# Docker Variables and Folders
docker_env_set()
	{
        echo -e "\e[1;36m> Setting Docker environment variables...\e[0m"
        echo "PUID=$uid" >> /etc/environment
        echo "PGID=$ugp" >> /etc/environment
        echo "TZ="$tzone"" >> /etc/environment
        echo "USERDIR=/home/$(logname)" >> /etc/environment
        echo "ROOTDIR="/opt/docker"" >> /etc/environment
        echo "DATADIR="/opt/docker/data"" >> /etc/environment
        echo "MYSQL_ROOT_PASSWORD="changeMe!"" >> /etc/environment

	    if [ ! -d "$docker_data" ]; then
		mkdir -p $docker_data
		fi

	    if [ ! -d "$docker_init" ]; then
		mkdir -p $docker_init
		fi
        rm -rf ./inst_temp
        echo -e "\e[1;36m> Docker variables set...\e[0m"
    }

# Docker Variables and Folders
docker_default_containers()
	{
        echo -e "\e[1;36m> Setting Default Docker Containers...\e[0m"
        default_container_names
	    cp $CURRENT_DIR/config/docker-compose.yml $docker_dir
        cp $CURRENT_DIR/config/apps/guacamole/initdb.sql $docker_init
        echo -e "\e[1;36m> Containers config added...\e[0m"
        rm -rf ./inst_2_temp
        touch ./inst_3_temp

        #Reload shell
        shell_reload
    }

# Pull containers
docker_pull_containers()
	{
        echo -e "\e[1;36m> Pulling containers...\e[0m"
        cd $docker_dir
        docker-compose up -d
        echo -e "\e[1;36m> Done!!!...\e[0m"
        echo 
        cd $CURRENT_DIR

    }

docker_cont_config_update()
	{
        echo -e "\e[1;36m> Updating container config...\e[0m"
        cd $docker_dir
        docker-compose up -d
        echo -e "\e[1;36m> Done!!!...\e[0m"
        echo 
        cd $CURRENT_DIR

    }

docker_img_cleanup()
	{
        echo -e "\e[1;36m> Cleaning up...\e[0m"
        cd $docker_dir
        docker system prune && docker image prune && docker volume prune
        echo -e "\e[1;36m> Done!!!...\e[0m"
        echo 
        cd $CURRENT_DIR

    }               
        

# Docker Installation
test_env_set()
	{
        echo "timezone = $tzone"
        echo "user = $uid"
        echo "docker group = $ugp"
        echo "Ubuntu Codename = $ubu_code"
        echo "branch_test = $branch"
        echo
        echo "Testing TEMP ENV variables"
        echo "export PUID=$uid"
        echo "export PGID=$ugp"
        echo "export TZ="$tzone""
        echo "export USERDIR="/home/$(logname)""
        echo "export ROOTDIR="/opt/docker""
        echo "export DATADIR="/opt/docker/data""
        echo "export MYSQL_ROOT_PASSWORD="changeMe!""
        read
 
	}

 shell_reload()
	{
        sleep 3s
		chmod +x $BASH_SOURCE
		exec ./install.sh

    }   

#script Updater
gh_updater_mod()
	{
		echo
		echo "Which branch do you want to pull?"
		echo "- [1] = Master [2] = Dev [3] = Exp"
		read -r gh_branch_no
		echo

		if [ $gh_branch_no = "1" ]
		then 
		gh_branch_name=master
				
		elif [ $gh_branch_no = "2" ]
		then 
		gh_branch_name=dev
	
		elif [ $gh_branch_no = "3" ]
		then 
		gh_branch_name=exp
		fi

		git fetch --all
		git reset --hard origin/$gh_branch_name
		git pull origin $gh_branch_name
		echo
        echo -e "\e[1;36mScript updated, reloading now...\e[0m"
        shell_reload
	}

show_menus() 
	{
	    if [ -e "./inst_temp" ]; then
        docker_env_set
        sleep 3s
        clear
		fi

        if [ -e "./inst_2_temp" ]; then
        docker_default_containers
        sleep 3s
        clear
		fi

        if [ -e "./inst_3_temp" ]; then
        test_env_set
        docker_pull_containers
        sleep 3s
        clear
		fi


		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		echo -e " 	  \e[1;36mDocker- INSTALLER $version  \e[0m"
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		echo " 1. Install Docker + Docker Compose  " 
		echo " 2. Install Docker/Docker Compose + Containers [Coming Soon] "
        echo " 3. Update Docker Container Config "
        echo " 4. Docker Image Cleanup "        
        echo " 5. Script Updater "
        echo " 8. Quit		 "
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		echo
		printf "\e[1;36m> Enter your choice: \e[0m"
	}
        read_options(){
		read -r options

		case $options in
	 	"1")
			echo "- Your choice: 1. Install Docker & Docker Compose"
            echo
            script_prereq
            docker_install
                	echo -e "\e[1;36m> \e[0mPress any key to return to menu..."
			read
		;;

	 	"2")
			echo "- Your choice 2: Install Docker/Docker Compose + Containers [coming soon]"
            touch ./inst_2_temp
            script_prereq
            docker_install
            shell_reload
            docker_default_containers
            rm -rf ./inst_3_temp
                	echo -e "\e[1;36m> \e[0mPress any key to return to menu..."
			read
		;; 

	 	"3")
			echo "- Your choice 3: Update Docker Container Config"
            docker_cont_config_update
			echo -e "\e[1;36m> \e[0mPress any key to return to menu..."
			read
		;;

	 	"4")
			echo "- Your choice 3: Docker Image Cleanup"
            docker_img_cleanup
            echo -e "\e[1;36m> \e[0mPress any key to return to menu..."
			read
		;;        
        
	 	"5")
	        gh_updater_mod
		;;

	 	"6")
            test_env_set
            read
		;;        

		"7")
			while true 
			do
			clear
			uti_menus
			uti_options
			done
		;;
        
		"8")
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