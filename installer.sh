#!/bin/bash
# Defines
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
WHITE='\033[47m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
MIN_FREE_SPACE=10
#functions
verify_disk_space(){
    local FREE_SPACE=$(df --output=avail -BG / | tail -n 1 | tr -d 'G')
	if((FREE_SPACE >= MIN_FREE_SPACE));then
		echo_green "Free space is valid, current is ${FREE_SPACE}"
	else
		echo_red "Insufficient free space to install and run. ${MIN_FREE_SPACE}GB required, ${FREE_SPACE} availible."
		exit 1
	fi
}
echo_green(){
	echo -e "${GREEN}$1${NC}"
}
echo_yellow(){
	echo -e "${YELLOW}$1${NC}"
}
echo_red(){
	echo -e "${RED}$1${NC}"
}
echo_blue(){
	echo -e "${WHITE}${BLUE}$1${NC}"
}
echo_cyan() {
    echo -e "${CYAN}$1${NC}"
}
#verify disk space
verify_disk_space
#get the name of the arma service from the user.
while true; do
	echo_yellow "What is the name of the server, no spaces?. Letters, numbers, -, and _ only."
	read servicename
	if [[ "$servicename" =~ ^[a-zA-Z0-9_-]+$ ]]; then
		echo_green "Will create a new server with the name $servicename"
		break
	else
		echo_red "Please try again with only letters, numbers, -, or _."
	fi
done
# get a port number and validate
while true; do
	echo_yellow "Enter a port number between 1000 and 65535, default is 2001 "
    read port
    if [[ $port =~ ^[0-9]+$ ]] && (( port >= 1000 && port <= 65535 )); then
        echo_green "Creating service with port number $port"
        break
    else
        echo_red "Invalid port number, please try again."
    fi
done
echo_yellow "What is the public name for the server?"
read publicname
echo_yellow "Type in a server password, if no password needed leave blank"
read password
echo_yellow "Type in a server administrator password"
read adminpassword
#create the service 	
cat <<EOF | sudo tee "/etc/systemd/system/$servicename.service"
[Unit]
Description=Arma Reforger Server $servicename
After=network.target

[Service]
ExecStart=/home/$servicename/reforger/run.sh
Restart=always
User=root
Group=root
TimeoutStartSec=300
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

[Install]
WantedBy=multi-user.target
EOF

#create the service user 
useradd -m -s /usr/sbin/nologin "$servicename"
passwd -l "$servicename"
addgroup servermanager
usermod -aG servermanager "$servicename"
echo "$servicename ALL=(ALL:ALL) NOPASSWD: /home/$servicename/*" | sudo tee -a /etc/sudoers
echo_green "Starting on the install of the packages, steam, and Arma Reforger"
#start the package install
apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y
apt-get install libcurl4 -y
apt-get install net-tools -y
echo "deb http://security.ubuntu.com/ubuntu impish-security main" | sudo tee /etc/apt/sources.list.d/impish-security.list
#wget http://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1-1ubuntu2.1~18.04.20_amd64.deb
#dpkg -i libssl1.1_1.1.1-1ubuntu2.1~18.04.20_amd64.deb
add-apt-repository multiverse -y
dpkg --add-architecture i386
apt update
apt install lib32gcc-s1 -y
#install steamcmd and auto accept EULA
echo steam steam/license note '' | debconf-set-selections
echo steam steam/question select "I AGREE" | debconf-set-selections
apt install steamcmd -y
#install Arma 
echo_green "installing Arma Reforger Server, this will take a bit"
steamcmd +force_install_dir "/home/$servicename/reforger" +login anonymous +app_update 1874900 +quit
#create the run.sh file
cat <<EOF | sudo tee "/home/$servicename/reforger/run.sh"
#!/bin/bash
/home/$servicename/reforger/ArmaReforgerServer -maxFPS 60 -gproj /home/$servicename/reforger/addons/data/ArmaReforger.gproj -config /home/$servicename/reforger/configs/Basic.json -backendlog -nothrow -profile /home/$servicename/reforger/profile/ -loadSessionSave -addonsDir /home/$servicename/reforger/addons >> /var/log/$servicename.log 2>&1
EOF
cat <<EOF | sudo tee "/home/$servicename/reforger/run.sh.CONSOLE_LOG"
#!/bin/bash
/home/$servicename/reforger/ArmaReforgerServer -maxFPS 60 -gproj /home/$servicename/reforger/addons/data/ArmaReforger.gproj -config /home/$servicename/reforger/configs/Basic.json -backendlog -nothrow -profile /home/$servicename/reforger/profile/ -loadSessionSave -addonsDir /home/$servicename/reforger/addons
EOF
#create the config and profile folders
mkdir "/home/$servicename/reforger/configs"
mkdir "/home/$servicename/reforger/profile"
echo_green "Folders and configuration files have been created"
echo_green "Creating a basic server config, edit at /home/$servicename/reforger/configs/Basic.json"
cat <<EOF | sudo tee "/home/$servicename/reforger/configs/Basic.json"
{
    "publicAddress": "",
    "publicPort": $port,
    "bindAddress": "",
    "bindPort": $port,
    "a2s": {
        "address": "127.0.0.1",
        "port": 17777
    },
    "rcon": {
        "address": "127.0.0.1",
        "port": 19999,
        "password": "$adminpassword",
        "permission": "monitor",
        "blacklist": [],
        "whitelist": []
    },
    "game": {
        "name": "$publicname",
        "password": "$password",
        "passwordAdmin": "$adminpassword",
        "admins": [],
        "scenarioId": "{3AB84052F4245DB1}Missions/EveronPVE.conf",
        "maxPlayers": 10,
        "visible": true,
        "crossPlatform": true,
        "supportedPlatforms": [
            "PLATFORM_PC",
            "PLATFORM_XBL"
        ],
        "gameProperties": {
            "serverMaxViewDistance": 2500,
            "serverMinGrassDistance": 50,
            "networkViewDistance": 1000,
            "disableThirdPerson": false,
            "fastValidation": true,
            "battlEye": true,
            "VONDisableUI": true,
            "VONDisableDirectSpeechUI": true,
            "missionHeader": {
                "m_iPlayerCount": 40,
                "m_eEditableGameFlags": 6,
                "m_eDefaultGameFlags": 6,
                "m_bUseSetupMenu": 0,
                "other": "values"
            }
        },
        "mods": [{
                "name": "ACE Backblast",
                "modId": "60E573C9B04CC408"
            }, {
                "name": "ACE Carrying",
                "modId": "5DBD560C5148E1DA"
            }, {
                "name": "ACE Chopping",
                "modId": "5EB744C5F42E0800"
            }, {
                "name": "ACE Compass",
                "modId": "60C53A9372ED3964"
            }, {
                "name": "ACE Core",
                "modId": "60C4CE4888FF4621"
            }, {
                "name": "ACE Finger",
                "modId": "606C369BAC3F6CC3"
            }, {
                "name": "ACE Magazine Repack",
                "modId": "611CB1D409001EB0"
            }, {
                "name": "ACE Medical",
                "modId": "60C4C12DAE90727B"
            }, {
                "name": "ACE Trenches",
                "modId": "60EAEA0389DB3CC2"
            }, {
                "name": "BetterHitsEffects 3.0 Alpha",
                "modId": "59651354B2904BA6"
            }, {
                "name": "BetterMuzzleFlashes 2.0",
                "modId": "59674C21AA886D57"
            }, {
                "name": "BetterSounds 3.6",
                "modId": "597C0CF3A7AA8A99"
            }, {
                "name": "BetterTracers 2.0",
                "modId": "59673B6FBB95459F"
            }, {
                "name": "Combat Scenarios Everon",
                "modId": "6208D945C86DD107"
            }, {
                "name": "Dynamic Timescale",
                "modId": "62191221E50A878A"
            }, {
                "name": "ExplosionsEffects",
                "modId": "5A855AA2B4EE1169"
            }, {
                "name": "GM Persistent Loadouts",
                "modId": "5C73156675E11A0F"
            }, {
                "name": "Game Master Enhanced",
                "modId": "5964E0B3BB7410CE"
            }, {
                "name": "Game Master FX",
                "modId": "5994AD5A9F33BE57"
            }, {
                "name": "Keep Abandoned Vehicles",
                "modId": "60E2D7E5A20FABEB"
            }, {
                "name": "Keep Gun When Uncon",
                "modId": "6088A3044B7ECBFD"
            }, {
                "name": "Night Vision System",
                "modId": "59A30ACC02650E71"
            }, {
                "name": "TMT Better Supplies",
                "modId": "622746B0CE1DCB3C"
            }
        ]
    },
    "operating": {
        "lobbyPlayerSynchronise": false
    }
}
EOF
#setup the permissions.
echo_green "Setting up permissions"
chown -R :servermanager "/home/$servicename/reforger"
chmod -R 755 "/home/$servicename/reforger"
chmod +x "/home/$servicename/reforger/run.sh"
chmod +x "/home/$servicename/reforger/run.sh.CONSOLE_LOG"
chmod +x "/home/$servicename/reforger/ArmaReforgerServer"
#reload the daemon
systemctl daemon-reload
#create aliases to start and stop the server
echo_green "creating alias to start and stop server"
bash -c 'echo "stopser=\"systemctl stop `$servicename.service\"" >> /etc/environment'
bash -c 'echo "startser=\"systemctl start `$servicename.service\"" >> /etc/environment'
bash -c 'echo "statusser=\"systemctl status `$servicename.service\"" >> /etc/environment'
source /etc/environment
echo_cyan "The install is complete"
echo_cyan "Please run /home/$servicename/reforger/run.sh.CONSOLE_LOG to start the service for the first time"
echo_cyan "After confirming everything works, execute systemctl enable $servicename.service to make the server start on host start"
echo_cyan '$stopser will stop and $startser will start, $statusser will get status'
echo_cyan "Starting intial server run"
echo_cyan "##############################"
echo_cyan "##############################"
echo_cyan "##############################"
echo_cyan "##############################"
bash -c "/home/$servicename/reforger/run.sh.CONSOLE_LOG"

