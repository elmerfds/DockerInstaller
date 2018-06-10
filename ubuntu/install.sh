#!/bin/bash -e
#Docker Installer
#author: elmerfdz
version=v0.42.0-4

#Script Requirements
prereqname=('Curl' )
prereq=('curl')

#Default Container Names
container_name=('Portainer' 'Watchtower' 'PHPmyadmin' 'Mariadb' 'Organizr' 'Postgres' 'Guacamole')

#Script config variables
tzone=$(cat /etc/timezone)
uid=$(id -u $(logname))
user_home_dir="/home/$(logname)"
ugp=$(cut -d: -f3 < <(getent group docker))
ubu_code=$(cut -d: -f2 < <(lsb_release -c)| xargs)
docker_dir='/opt/docker'
docker_data='/opt/docker/data'
docker_init='/opt/docker/init'
CURRENT_DIR=`dirname $0`
env_file="/etc/environment"

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
        echo
		echo "- Docker and Docker Compose Installed"
        echo     
  
        #Reloading Shell, to get docker group id
        shell_reload
	}

# Docker Variables and Folders
docker_env_set()
	{
        echo
        echo -e "\e[1;36m> Setting Docker environment variables...\e[0m"
        echo
        if grep -Fxq "PUID=$uid" $env_file
        then
            echo "PUID already exists"
        else
            echo "PUID=$uid" >> /etc/environment
        fi

        if grep -Fxq "PGID=$ugp" $env_file
        then
            echo "PGID already exists"
        else
            echo "PGID=$ugp" >> /etc/environment
        fi

        if grep -Fxq 'TZ="'"$tzone"'"' $env_file
        then
            echo "TZ already exists"
        else
            echo 'TZ="'"$tzone"'"' >> /etc/environment
        fi        
        
        if grep -Fxq 'USERDIR="'"/home/$(logname)"'"' $env_file
        then
            echo "USERDIR already exists"
        else
            echo 'USERDIR="'"/home/$(logname)"'"' >> /etc/environment
        fi   

        if grep -Fxq 'ROOTDIR="'"$docker_dir"'"' $env_file
        then
            echo "ROOTDIR already exists"
        else
            echo 'ROOTDIR="'"$docker_dir"'"' >> /etc/environment
        fi           

        if grep -Fxq 'DATADIR="'"$docker_data"'"' $env_file
        then
            echo "DATADIR already exists"
        else
            echo 'DATADIR="'"$docker_data"'"' >> /etc/environment
        fi               

        if grep -Fxq 'MYSQL_ROOT_PASSWORD="changeMe!"' $env_file
        then
            echo "MYSQL_ROOT_PASSWORD already exists"
        else
            echo 'MYSQL_ROOT_PASSWORD="changeMe!"' >> /etc/environment
        fi          
        
        if [ ! -d "$docker_data" ]; then
		mkdir -p $docker_data
		fi

	    if [ ! -d "$docker_init" ]; then
		mkdir -p $docker_init
		fi
        echo
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
        #Reload shell
        source ~/.bashrc
    }

# Pull containers
docker_pull_containers()
	{
        echo -e "\e[1;36m> Pulling containers...\e[0m"
        echo
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
        echo -e "\e[1;34m$ docker-compose up -d\e[0m"
        echo
        docker-compose up -d
        echo
        echo -e "\e[1;36m> Done!!!...\e[0m"
        echo 
        cd $CURRENT_DIR
    }

docker_img_cleanup()
	{
        echo -e "\e[1;36m> Cleaning up...\e[0m"
        cd $docker_dir
        echo -e "\e[1;34m$ docker system prune && docker image prune && docker volume prune\e[0m"
        echo
        docker system prune && docker image prune && docker volume prune
        echo
        echo -e "\e[1;36m> Done!!!...\e[0m"
        echo 
        cd $CURRENT_DIR

    }      

docker_logs()
	{
        echo -e "\e[1;36m> List all logs? [A]\e[0m"
        echo -e "\e[1;36m> Specific Container Logs? [S]\e[0m"
        read -r logs_type
	    if [ $logs_type = "A" ] || [ $logs_type = "a" ]; 
        then
        cd $docker_dir
		docker-compose logs
        echo
	
        elif [ $logs_type = "S" ] || [ $logs_type = "s" ];
        then
        cd $docker_dir
        echo        
        sudo docker-compose images
        echo
        echo -e "\e[1;36m> Enter container name [A]\e[0m"
        read -r container_name
        docker logs $container_name
        fi
        echo 
        cd $CURRENT_DIR

    }             

additional_docker_config()
	{
        echo
        echo -e "\e[1;36m> Optional Docker install config\e[0m"       
        echo
        echo -e "\e[1;36m> Do you want to run docker commands without sudo for the current user? [y/n]\e[0m"
        printf '\e[1;36m- \e[0m'    
        read -r dc_no_sudo
        dc_no_sudo=${dc_no_sudo:-y}
	    if [ $dc_no_sudo = "Y" ] || [ $dc_no_sudo = "y" ];
        then
            echo
            gpasswd -a $SUDO_USER docker
            echo "Done!"
        else
            echo    
            echo "Skipped" 
        fi

        echo
        echo -e "\e[1;36m> Do you want to create an env variable ('dc'), so that you can run docker-compose commands from any directory? [y/n]\e[0m"
        echo -e "e.g:" '$dc' "up -d"  "\e[1;36m = docker-compose up -d\e[0m"
        echo -e "e.g:" '$dcf' "\e[1;36m = /opt/docker/docker-compose.yml \e[0m"
        printf '\e[1;36m- \e[0m'    
        read -r dc_dcom_var
        dc_dcom_var=${dc_dcom_var:-y}
        if [ $dc_dcom_var = "Y" ] || [ $dc_dcom_var = "y" ];
        then
            echo
            if grep -Fxq 'dc="docker-compose -f '"/opt/docker/docker-compose.yml"'"' $env_file
            then
                echo "dc variable already exists"
            else
                echo 'dc="docker-compose -f '"/opt/docker/docker-compose.yml"'"' >> /etc/environment
            fi

            if grep -Fxq 'dcf='"/opt/docker/docker-compose.yml"'' $env_file 
            then
                echo "dcf variable already exists"
            else
                echo 'dcf="'"/opt/docker/docker-compose.yml"'"' >> /etc/environment
            fi   
            echo "Done!"
            echo
        else
            echo "Skipped"
        fi
        
        if [ $dc_dcom_var = "Y" ] || [ $dc_dcom_var = "y" ] || [ $dc_no_sudo = "Y" ] || [ $dc_no_sudo = "y" ];
        then
            echo
            echo -e "\e[1;36m> \e[0mDocker Install completed" 
            echo
            echo -e "\e[1;36m> \e[0mPress any key to quit the script and refresh login session."
            read
            maintainer_cleanup
            sudo -u $SUDO_USER bash --login

        elif [ $dc_dcom_var = "N" ] || [ $dc_dcom_var = "n" ];
        then
            echo
            maintainer_cleanup
            echo -e "\e[1;36m> \e[0mDocker Install completed"
            echo 
            echo -e "\e[1;36m> \e[0mPress any key to return to menu..."   
            read
            source ~/.bashrc  
        fi
       
	}        

# Debug env vars
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
        sleep 1s
		chmod +x $BASH_SOURCE
		exec ./install.sh
    } 

maintainer_cleanup()
    {
        rm -rf ./inst_temp
        rm -rf ./inst_2_temp
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
            additional_docker_config
            sleep 3s
            clear
		fi
        
        if [ -e "./inst_2_temp" ]; then
            docker_env_set
            docker_default_containers
            docker_pull_containers
            additional_docker_config
            rm -rf ./inst_2_temp
            sleep 3s
            clear
		fi

        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		echo -e " 	  \e[1;36mDOCKER - INSTALLER $version  \e[0m"
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		echo " 1. Install Docker + Docker Compose  " 
		echo " 2. Install Docker/Docker Compose + Containers"
        echo " 3. Update Docker Container Config "
        echo " 4. Docker Image Cleanup "      
        echo " 5. Docker Logs "  
        echo " 6. Script Updater "
        echo " 9. Quit		 "
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
            #install maintainer
            touch ./inst_temp
            script_prereq
            docker_install
		;;

	 	"2")
			echo "- Your choice 2: Install Docker/Docker Compose + Containers [coming soon]"
            echo
            #install maintainer
            touch ./inst_2_temp
            script_prereq
            docker_install
            source ~/.bashrc
            docker_env_set
            docker_default_containers
            docker_pull_containers
            additional_docker_config
            echo -e "\e[1;36m> \e[0mPress any key to return to menu..."
			read
		;; 

	 	"3")
			echo "- Your choice 3: Update Docker Container Config"
            echo
            docker_cont_config_update
			echo -e "\e[1;36m> \e[0mPress any key to return to menu..."
			read
		;;

	 	"4")
			echo "- Your choice 4: Docker Image Cleanup"
            echo
            docker_img_cleanup
            echo -e "\e[1;36m> \e[0mPress any key to return to menu..."
			read
		;;

	 	"5")
			echo "- Your choice 5: Docker Logs"
            echo
            docker_logs
            echo -e "\e[1;36m> \e[0mPress any key to return to menu..."
			read
		;;            
        
	 	"6")
	        gh_updater_mod
		;;

	 	"7")
            test_env_set
            read
		;;        

		"8")
			while true 
			do
			clear
			uti_menus
			uti_options
			done
		;;
        
		"9")
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