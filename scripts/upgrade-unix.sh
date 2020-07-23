#!/bin/bash

# Functions
readYesNo()
{
	PROMPT=$1
	DEFAULT=$2
	while true; do
		read -p "${BLUE_READ}$PROMPT [$DEFAULT]: ${NC_READ}" ANSWER
		ANSWER="${ANSWER:-$DEFAULT}"
		case $ANSWER in
			[Yy]* ) return 1;;
			[Nn]* ) return 0;;
			* ) echo "Please answer Y or N.";;
		esac
	done
}

# Options
SOURCES_PATH_DEFAULT=$HOME
SOURCES_PATH="$SOURCES_PATH_DEFAULT/intarocryptocurrency"
BACKUP_PATH_DEFAULT=$HOME/intarocryptocurrencybackup
BACKUP_PATH=$BACKUP_PATH_DEFAULT
REPO="https://github.com/intarocryptocurrency/intarocryptocurrency"
BRANCH="master"
SWAP_FILE="$HOME/intarocryptocurrency-swap"

# Useful variables
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BLUE_READ=$'\e[34m'
NC='\033[0m'
NC_READ=$'\e[0m'

# System specs
NB_CORES=`nproc`
MEMORY_SIZE=`grep MemTotal /proc/meminfo | awk '{print $2}'`

# Install Git
echo -e "\n${GREEN}Installing git${NC}"
if [ -n "$(command -v yum)" ]; then
    sudo yum install git
elif [ -n "$(command -v apt-get)" ]; then
    sudo apt-get install git
fi

# Clone / update repo if executing the script as a standalone script
if [ -d "../.git" ]; then
	# Script is executed from repo
	echo -e "\n${GREEN}Script executed from the repository${NC}"
	SOURCES_PATH="$(dirname "$(pwd)")"
	# Delete previous binary
	if [ -f "$SOURCES_PATH/bin/intarocryptocurrencyd" ]; then
		rm -f $SOURCES_PATH/bin/intarocryptocurrencyd
		echo -e "${BLUE}Removed old binary in $SOURCES_PATH/bin/${NC}"
	fi
	if [ -f "../bin/intarocryptocurrencyd" ]; then
      rm ../bin/intarocryptocurrencyd
      echo "Removed old binary in ../bin/"
    fi
else
	# Standalone mode
	echo -e "\n${GREEN}Standalone mode${NC}"

	# Ask for the install path
	read -e -p "${BLUE_READ}Install to directory [$SOURCES_PATH_DEFAULT]: ${NC_READ}" SOURCES_PATH
	SOURCES_PATH="${SOURCES_PATH:-$SOURCES_PATH_DEFAULT}/intarocryptocurrency"
	# Replace ~ with $HOME if needed
	SOURCES_PATH="${SOURCES_PATH/[~]/$HOME}"

	# Clone / update the repo
	if [ -d $SOURCES_PATH ]; then
		cd $SOURCES_PATH
		git checkout $BRANCH
		git pull
	else
		mkdir -p $SOURCES_PATH
		git clone -b $BRANCH $REPO $SOURCES_PATH
	fi
fi

if [ ! -d $SOURCES_PATH ]; then
	echo -e "\n${RED}ERROR: installation folder could not be created${NC}"
	exit -1
fi

# Kill and remove existing daemons
echo -e "\n${GREEN}Removing existing daemons${NC}"
sudo killall -9 intarocryptocurrencyd
if [ -f "/usr/local/bin/intarocryptocurrencyd" ]; then
  sudo rm -f /usr/local/bin/intarocryptocurrencyd
  echo -e "${BLUE}Removed intarocryptocurrencyd in /usr/local/bin/ - To be replaced with new version${NC}"
fi

# Go to the scripts directory
cd $SOURCES_PATH/scripts

# Install dependencies
echo -e "\n${GREEN}Installing dependencies${NC}"
readYesNo "Install dependencies for Ubuntu? This will NOT install any dependencies if you say no!" "N"
INSTALL_DEPS=$?
if [ "$INSTALL_DEPS" = 1 ]; then
	./install-dependencies.sh
fi

# Cleaning repo
echo -e "\n${GREEN}Cleaning repo${NC}"
./clean.sh

if [ ! -e checkswap.sh ] ; then
    wget https://raw.githubusercontent.com/intarocryptocurrency/intarocryptocurrency/master/scripts/checkswap.sh
fi
./checkswap.sh

# Build daemon
echo -e "\n${GREEN}Building daemon${NC}"
cd $SOURCES_PATH/src
make -j$NB_CORES -f makefile.unix

if [ ! -f $SOURCES_PATH/bin/intarocryptocurrencyd ]; then
	echo -e "\n${RED}ERROR: intarocryptocurrencyd binary could not be created${NC}"
	exit -2
fi

# Build QT GUI
echo -e "\n${GREEN}Building GUI${NC}"
readYesNo "Build GUI" "N"
BUILD_GUI=$?
if [ "$BUILD_GUI" = 1 ]; then
	cd $SOURCES_PATH
	qmake CONFIG+=debug
	make -j$NB_CORES
fi

# Remove swap
if [ -f "$SWAP_FILE" ]; then
	sudo swapoff $SWAP_FILE
	sudo rm -f $SWAP_FILE
fi

# Install
echo -e "\n${GREEN}Installing daemon in /usr/local/bin/${NC}"
sudo cp $SOURCES_PATH/bin/intarocryptocurrencyd /usr/local/bin/
sudo strip /usr/local/bin/intarocryptocurrencyd

# Backup data dir
if [ -d "$HOME/.Intarocryptocurrency/" ]; then
	echo -e "\n${GREEN}Backing up ~/Intarocryptocurrency (including wallet.dat)${NC}"

	# Ask for the install path
	read -e -p "${BLUE_READ}Backup directory [$BACKUP_PATH_DEFAULT]: ${NC_READ}" BACKUP_PATH
	BACKUP_PATH="${BACKUP_PATH:-$BACKUP_PATH_DEFAULT}"
	# Replace ~ with $HOME if needed
	BACKUP_PATH="${BACKUP_PATH/[~]/$HOME}"

	if [ ! -d "$BACKUP_PATH" ]; then
		mkdir -p $BACKUP_PATH
	fi

	DATE=`date '+%Y%m%d-%H%M%S'`
	CURRENT_BACKUP_PATH=$BACKUP_PATH/$DATE
	mkdir $CURRENT_BACKUP_PATH

	if [ ! -d $CURRENT_BACKUP_PATH ]; then
		echo -e "\n${RED}ERROR: backup folder could not be created${NC}"
		exit -1
	fi

	cd $HOME/.Intarocryptocurrency/  
	rm -rf smsgStore
	rm -rf smsgDB
	rm -f *.log
	rm -f smsg.ini
	rm -f blk*
	rm -rf database
	rm -rf txleveldb
	rm -f peers.dat
	rm -f mncache.dat
	cp -r * $CURRENT_BACKUP_PATH
fi

# Done
echo -e "\n${GREEN}Upgrade Complete - You can now run intarocryptocurrencyd or fill out the config file in ~/Intarocryptocurrency${NC}"

