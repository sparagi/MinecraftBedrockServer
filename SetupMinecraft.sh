#!/bin/bash
# Minecraft Server Installation Script - James A. Chambers - https://jamesachambers.com
#
# Instructions: https://jamesachambers.com/minecraft-bedrock-edition-ubuntu-dedicated-server-guide/
# To run the setup script use:
# wget https://raw.githubusercontent.com/TheRemote/MinecraftBedrockServer/master/SetupMinecraft.sh
# chmod +x SetupMinecraft.sh
# ./SetupMinecraft.sh
#
# GitHub Repository: https://github.com/TheRemote/MinecraftBedrockServer

echo "Minecraft Bedrock Server installation script by James Chambers"
echo "Latest version always at https://github.com/TheRemote/MinecraftBedrockServer"
echo "Don't forget to set up port forwarding on your router!  The default port is 19132"

# Check for updates
if [[ $(find "SetupMinecraft.sh" -mtime +7 -print) ]]; then
  echo "Performing self update..."
  wget -O SetupMinecraft.sh https://raw.githubusercontent.com/TheRemote/MinecraftBedrockServer/master/SetupMinecraft.sh
  chmod +x SetupMinecraft.sh
  /bin/bash SetupMinecraft.sh
  exit 0
fi

# Function to read input from user with a prompt
function read_with_prompt {
  variable_name="$1"
  prompt="$2"
  default="${3-}"
  unset $variable_name
  while [[ ! -n ${!variable_name} ]]; do
    read -p "$prompt: " $variable_name < /dev/tty
    if [ ! -n "`which xargs`" ]; then
      declare -g $variable_name=$(echo "${!variable_name}" | xargs)
    fi
    declare -g $variable_name=$(echo "${!variable_name}" | head -n1 | awk '{print $1;}')
    if [[ -z ${!variable_name} ]] && [[ -n "$default" ]] ; then
      declare -g $variable_name=$default
    fi
    echo -n "$prompt : ${!variable_name} -- accept (y/n)?"
    read answer < /dev/tty
    if [ "$answer" == "${answer#[Yy]}" ]; then
      unset $variable_name
    else
      echo "$prompt: ${!variable_name}"
    fi
  done
}

# Check to make sure we aren't being ran as root
if [ $(id -u) = 0 ]; then
   echo "This script is not meant to be ran as root or sudo.  Please run normally with ./SetupMinecraft.sh.  If you know what you are doing and want to override this edit this check out of SetupMinecraft.sh.  Exiting..."
   exit 1
fi

# Install dependencies required to run Minecraft server in the background
echo "Installing screen, unzip, sudo, net-tools, wget.."
if [ ! -n "`which sudo`" ]; then
  apt-get update && apt-get install sudo -y
fi
sudo apt-get update
sudo apt-get install screen unzip wget -y
sudo apt-get install net-tools -y
echo "Installing curl and libcurl.."
sudo apt-get install curl -y
sudo apt-get install libcurl4 -y
# Install libcurl3 for backwards compatibility in case libcurl4 isn't available
sudo apt-get install libcurl3 -y
echo "Installing openssl, libc6 and libcrypt1.."
sudo apt-get install openssl -y
sudo apt-get install libc6 -y
sudo apt-get install libcrypt1 -y

# Check to see if Minecraft server main directory already exists
cd ~
if [ ! -d "minecraftbe" ]; then
  mkdir minecraftbe
  cd minecraftbe
else
  cd minecraftbe
  if [ -f "bedrock_server" ]; then
    echo "Migrating old Bedrock server to minecraftbe/old"
    cd ~
    mv minecraftbe old
    mkdir minecraftbe
    mv old minecraftbe/old
    cd minecraftbe
    echo "Migration complete to minecraftbe/old"
  fi
fi

# Server name configuration
echo "Enter a short one word label for a new or existing server (don't use minecraftbe)..."
echo "It will be used in the folder name and service name..."

read_with_prompt ServerName "Server Label"

if [[ "$ServerName" == *"minecraftbe"* ]]; then
  echo "Server label of minecraftbe is not allowed.  Please choose a different server label!"
  exit 1
fi

echo "Enter server IPV4 port (default 19132): "
read_with_prompt PortIPV4 "Server IPV4 Port" 19132

echo "Enter server IPV6 port (default 19133): "
read_with_prompt PortIPV6 "Server IPV6 Port" 19133

if [ -d "$ServerName" ]; then
  echo "Directory minecraftbe/$ServerName already exists!  Updating scripts and configuring service ..."

  # Get Home directory path and username
  DirName=$(readlink -e ~)
  UserName=$(whoami)
  cd ~
  cd minecraftbe
  cd $ServerName
  echo "Server directory is: $DirName/minecraftbe/$ServerName"

  # Remove existing scripts
  rm start.sh stop.sh restart.sh fixpermissions.sh

  # Download start.sh from repository
  echo "Grabbing start.sh from repository..."
  wget -O start.sh https://raw.githubusercontent.com/TheRemote/MinecraftBedrockServer/master/start.sh
  chmod +x start.sh
  sed -i "s:dirname:$DirName:g" start.sh
  sed -i "s:servername:$ServerName:g" start.sh
  sed -i "s:userxname:$UserName:g" start.sh
  sed -i "s<pathvariable<$PATH<g" start.sh

  # Download stop.sh from repository
  echo "Grabbing stop.sh from repository..."
  wget -O stop.sh https://raw.githubusercontent.com/TheRemote/MinecraftBedrockServer/master/stop.sh
  chmod +x stop.sh
  sed -i "s:dirname:$DirName:g" stop.sh
  sed -i "s:servername:$ServerName:g" stop.sh
  sed -i "s:userxname:$UserName:g" stop.sh
  sed -i "s<pathvariable<$PATH<g" stop.sh

  # Download restart.sh from repository
  echo "Grabbing restart.sh from repository..."
  wget -O restart.sh https://raw.githubusercontent.com/TheRemote/MinecraftBedrockServer/master/restart.sh
  chmod +x restart.sh
  sed -i "s:dirname:$DirName:g" restart.sh
  sed -i "s:servername:$ServerName:g" restart.sh
  sed -i "s:userxname:$UserName:g" restart.sh
  sed -i "s<pathvariable<$PATH<g" restart.sh

  # Download fixpermissions.sh from repository
  echo "Grabbing fixpermissions.sh from repository..."
  wget -O fixpermissions.sh https://raw.githubusercontent.com/TheRemote/MinecraftBedrockServer/master/fixpermissions.sh
  chmod +x fixpermissions.sh
  sed -i "s:dirname:$DirName:g" fixpermissions.sh
  sed -i "s:servername:$ServerName:g" fixpermissions.sh
  sed -i "s:userxname:$UserName:g" fixpermissions.sh

  # Update minecraft server service
  echo "Configuring Minecraft $ServerName service..."
  sudo wget -O /etc/systemd/system/$ServerName.service https://raw.githubusercontent.com/TheRemote/MinecraftBedrockServer/master/minecraftbe.service
  sudo chmod +x /etc/systemd/system/$ServerName.service
  sudo sed -i "s:userxname:$UserName:g" /etc/systemd/system/$ServerName.service
  sudo sed -i "s:dirname:$DirName:g" /etc/systemd/system/$ServerName.service
  sudo sed -i "s:servername:$ServerName:g" /etc/systemd/system/$ServerName.service
  sed -i "/server-port=/c\server-port=$PortIPV4" server.properties
  sed -i "/server-portv6=/c\server-portv6=$PortIPV6" server.properties
  sudo systemctl daemon-reload
  echo -n "Start Minecraft server at startup automatically (y/n)?"
  read answer < /dev/tty
  if [ "$answer" != "${answer#[Yy]}" ]; then
    sudo systemctl enable $ServerName.service

    # Automatic reboot at 4am configuration
    echo -n "Automatically restart and backup server at 4am daily (y/n)?"
    read answer < /dev/tty
    if [ "$answer" != "${answer#[Yy]}" ]; then
      croncmd="$DirName/minecraftbe/$ServerName/restart.sh"
      cronjob="0 4 * * * $croncmd"
      ( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -
      echo "Daily restart scheduled.  To change time or remove automatic restart type crontab -e"
    fi
  fi

  # Setup completed
  echo "Setup is complete.  Starting Minecraft $ServerName server..."
  sudo systemctl start $ServerName.service

  # Sleep for 4 seconds to give the server time to start
  sleep 4s

  screen -r $ServerName

  exit 0
fi

# Create server directory
echo "Creating minecraft server directory (~/minecraftbe/$ServerName)..."
cd ~
cd minecraftbe
mkdir $ServerName
cd $ServerName
mkdir downloads
mkdir backups
mkdir logs

# Check CPU archtecture to see if we need to do anything special for the platform the server is running on
echo "Getting system CPU architecture..."
CPUArch=$(uname -m)
echo "System Architecture: $CPUArch"

# Check for ARM architecture
if [[ "$CPUArch" == *"aarch"* || "$CPUArch" == *"arm"* ]]; then
  # ARM architecture detected -- download QEMU and dependency libraries
  echo "ARM platform detected -- installing dependencies..."
  # Check if latest available QEMU version is at least 3.0 or higher
  QEMUVer=$(apt-cache show qemu-user-static | grep Version | awk 'NR==1{ print $2 }' | cut -c3-3)
  if [[ "$QEMUVer" -lt "3" ]]; then
    echo "Available QEMU version is not high enough to emulate x86_64.  Please update your QEMU version."
    exit
  else
    sudo apt-get install qemu-user-static binfmt-support -y
  fi

  if [ -n "`which qemu-x86_64-static`" ]; then
    echo "QEMU-x86_64-static installed successfully"
  else
    echo "QEMU-x86_64-static did not install successfully -- please check the above output to see what went wrong."
    exit 1
  fi
  
  # Retrieve depends.zip from GitHub repository
  wget -O depends.zip https://raw.githubusercontent.com/TheRemote/MinecraftBedrockServer/master/depends.zip
  unzip depends.zip
  sudo mkdir /lib64
  # Create soft link ld-linux-x86-64.so.2 mapped to ld-2.31.so
  sudo ln -s ~/minecraftbe/$ServerName/ld-2.31.so /lib64/ld-linux-x86-64.so.2
fi

# Check for x86 (32 bit) architecture
if [[ "$CPUArch" == *"i386"* || "$CPUArch" == *"i686"* ]]; then
  # ARM architecture detected -- download QEMU and dependency libraries
  #echo "32 bit platform detected -- installing dependencies..."
  # Check if latest available QEMU version is at least 3.0 or higher
  #QEMUVer=$(apt-cache show qemu-user-static | grep Version | awk 'NR==1{ print $2 }' | cut -c3-3)
  #if [[ "$QEMUVer" -lt "3" ]]; then
  #  echo "Available QEMU version is not high enough to emulate x86_64.  Please update your QEMU version."
  #  exit
  #else
  #  sudo apt-get install qemu-user-static binfmt-support -y
  #fi

  #if [ -n "`which qemu-x86_64-static`" ]; then
  #  echo "QEMU-x86_64-static installed successfully"
  #else
  #  echo "QEMU-x86_64-static did not install successfully -- please check the above output to see what went wrong."
  #  exit 1
  #fi
  
  # Retrieve depends.zip from GitHub repository
  #wget -O depends.zip https://raw.githubusercontent.com/TheRemote/MinecraftBedrockServer/master/depends.zip
  #unzip depends.zip
  #sudo mkdir /lib64
  # Create soft link ld-linux-x86-64.so.2 mapped to ld-2.31.so
  #sudo ln -s ~/minecraftbe/$ServerName/ld-2.31.so /lib64/ld-linux-x86-64.so.2

  # 32 bit attempts have not been successful -- notify user to install 64 bit OS
  echo "You are running a 32 bit operating system (i386 or i686) and the Bedrock Dedicated Server has only been released for 64 bit (x86_64).  If you have a 64 bit processor please install a 64 bit operating system to run the Bedrock dedicated server!"
  exit 1
fi

# Retrieve latest version of Minecraft Bedrock dedicated server
echo "Checking for the latest version of Minecraft Bedrock server..."
wget -U "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36" -O downloads/version.html https://minecraft.net/en-us/download/server/bedrock/
DownloadURL=$(grep -o 'https://minecraft.azureedge.net/bin-linux/[^"]*' downloads/version.html)
DownloadFile=$(echo "$DownloadURL" | sed 's#.*/##')
echo "$DownloadURL"
echo "$DownloadFile"

# Download latest version of Minecraft Bedrock dedicated server
echo "Downloading the latest version of Minecraft Bedrock server..."
UserName=$(whoami)
DirName=$(readlink -e ~)
wget -U "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36" -O "downloads/$DownloadFile" "$DownloadURL"
unzip -o "downloads/$DownloadFile"

# Download start.sh from repository
echo "Grabbing start.sh from repository..."
wget -O start.sh https://raw.githubusercontent.com/TheRemote/MinecraftBedrockServer/master/start.sh
chmod +x start.sh
sed -i "s:dirname:$DirName:g" start.sh
sed -i "s:servername:$ServerName:g" start.sh
sed -i "s:userxname:$UserName:g" start.sh
sed -i "s<pathvariable<$PATH<g" start.sh

# Download stop.sh from repository
echo "Grabbing stop.sh from repository..."
wget -O stop.sh https://raw.githubusercontent.com/TheRemote/MinecraftBedrockServer/master/stop.sh
chmod +x stop.sh
sed -i "s:dirname:$DirName:g" stop.sh
sed -i "s:servername:$ServerName:g" stop.sh
sed -i "s:userxname:$UserName:g" stop.sh
sed -i "s<pathvariable<$PATH<g" stop.sh

# Download restart.sh from repository
echo "Grabbing restart.sh from repository..."
wget -O restart.sh https://raw.githubusercontent.com/TheRemote/MinecraftBedrockServer/master/restart.sh
chmod +x restart.sh
sed -i "s:dirname:$DirName:g" restart.sh
sed -i "s:servername:$ServerName:g" restart.sh
sed -i "s:userxname:$UserName:g" restart.sh
sed -i "s<pathvariable<$PATH<g" restart.sh

# Download fixpermissions.sh from repository
echo "Grabbing fixpermissions.sh from repository..."
wget -O fixpermissions.sh https://raw.githubusercontent.com/TheRemote/MinecraftBedrockServer/master/fixpermissions.sh
chmod +x fixpermissions.sh
sed -i "s:dirname:$DirName:g" fixpermissions.sh
sed -i "s:servername:$ServerName:g" fixpermissions.sh
sed -i "s:userxname:$UserName:g" fixpermissions.sh

# Service configuration
echo "Configuring Minecraft $ServerName service..."
sudo wget -O /etc/systemd/system/$ServerName.service https://raw.githubusercontent.com/TheRemote/MinecraftBedrockServer/master/minecraftbe.service
sudo chmod +x /etc/systemd/system/$ServerName.service
sudo sed -i "s:userxname:$UserName:g" /etc/systemd/system/$ServerName.service
sudo sed -i "s:dirname:$DirName:g" /etc/systemd/system/$ServerName.service
sudo sed -i "s:servername:$ServerName:g" /etc/systemd/system/$ServerName.service
sed -i "/server-port=/c\server-port=$PortIPV4" server.properties
sed -i "/server-portv6=/c\server-portv6=$PortIPV6" server.properties
sudo systemctl daemon-reload

echo -n "Start Minecraft server at startup automatically (y/n)?"
read answer < /dev/tty
if [ "$answer" != "${answer#[Yy]}" ]; then
  sudo systemctl enable $ServerName.service

  # Automatic reboot at 4am configuration
  TimeZone=$(cat /etc/timezone)
  CurrentTime=$(date)
  echo "Your time zone is currently set to $TimeZone.  Current system time: $CurrentTime"
  echo "You can adjust/remove the selected reboot time later by typing crontab -e or running SetupMinecraft.sh again."
  echo -n "Automatically restart and backup server at 4am daily (y/n)?"
  read answer < /dev/tty
  if [ "$answer" != "${answer#[Yy]}" ]; then    
    croncmd="$DirName/minecraftbe/$ServerName/restart.sh"
    cronjob="0 4 * * * $croncmd"
    ( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -
    echo "Daily restart scheduled.  To change time or remove automatic restart type crontab -e"
  fi
fi

# Finished!
echo "Setup is complete.  Starting Minecraft server..."
sudo systemctl start $ServerName.service

# Wait up to 20 seconds for server to start
StartChecks=0
while [ $StartChecks -lt 20 ]; do
  if screen -list | grep -q "\.$ServerName"; then
    break
  fi
  sleep 1;
  StartChecks=$((StartChecks+1))
done

# Force quit if server is still open
if ! screen -list | grep -q "\.$ServerName"; then
  echo "Minecraft server failed to start after 20 seconds."
else
  echo "Minecraft server has started.  Type screen -r $ServerName to view the running server!"
fi

# Attach to screen
screen -r $ServerName
