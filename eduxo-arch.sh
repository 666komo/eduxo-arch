#!/bin/bash
# This script prepare VM eduxo Workstation on Ubuntu Server 22.04
# Tested on Ubuntu Server 22.04


# Must be install manual
# ======================
# Install archlinux-2023.02.01-x86_64.iso
# Install VBox Additions



# Test internet connection
function check_internet() {
  printf "Checking if you are online...\n"
  wget -q --spider http://github.com
  if [ $? -eq 0 ]; then
    echo -e '\e[0;92m\nOnline. Continuing.\e[0m'
  else
    echo -e '\e[0;91m\nOffline. Go connect to the internet then run the script again.\e[0m'
  fi
}
check_internet


echo -e '\e[1;92m\nStart installation.\e[0m'

sudo sh -c 'echo "
# Edit /etc/hosts
127.0.0.1       localhost
127.0.1.1       eduxo.lab	eduxo

10.20.30.40     server.eduxo.lab	server

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

2001:db8:acad::40   server.eduxo.lab	server
" > /etc/hosts'



#refresh repos
# Install upgrades and basic programs
echo -e '\e[0;92m\nInstalling basic programs, wait for completion.\e[0m'
sleep 3
sudo pacman --noconfirm -Sy
sudo pacman --noconfirm -Syu
sudo pacman --noconfirm -S firefox tigervnc asciinema xrdp wget yay curl gnupg docker


# Set NetworkManager
sudo sh -c 'echo "
# This is the network config written by 'subiquity'
network:
  renderer: NetworkManager
  ethernets:
    enp0s3:
      dhcp4: true
  version: 2
" > /etc/netplan/00-installer-config.yaml'


# Install GIT
sudo pacman --noconfirm -S git

# GIT clone
cd /home/sysadmin
sudo git clone https://github.com/eduxo/eduxo.git
# Update GIT eduxo on login
sh -c 'echo "
# eduxo
cd /home/eduxo/ && git pull > /dev/null 2>&1
" >> /home/.profile'

# Update GIT eduxo on login via rdp
sudo sh -c 'echo "

# eduxo
cd /home/sysadmin/eduxo/ && git pull > /dev/null 2>&1
" >> /etc/xrdp/startwm.sh'

#set up AUR
echo -e '\e[0;92m\nInstalling AUR\e[0m'
sudo pacman --noconfirm -S --needed base-devel git
git clone https://aur.archlinux.org/yay.git
sudo chmod 777 yay
cd yay
makepkg -si
cd /home/sysadmin

# Install Wireshark
echo "wireshark-common wireshark-common/install-setuid boolean true" 
sudo pacman --noconfirm -S wireshark wireshark-qt
# Add your user to the wireshark group
sudo useradd sysadmin wireshark
sudo useradd sysadmin wireshark-qt


# Install PackerTracer (CiscoPacketTracer_820_Ubuntu_64bit.deb)
wget --no-check-certificate 'https://drive.google.com/uc?id=1wIY2XxRshMLwWlO_ki5WRUTC1wYRUl0z&confirm=no_antivirus&export=download' -O 'CiscoPacketTracer_820_Ubuntu_64bit.deb'
cd /Downloads/
git clone https://aur.archlinux.org/packettracer.git
cp -r /Downloads/CiscoPacketTracer_820_Ubuntu_64bit.deb ~/packettracer/
cd /packettracer/
makepkg -si
cd /home/sysadmin

echo -e '\e[0;92m\nInstallation basic programs is completed.\e[0m'
sleep 3


# GNS3 (https://docs.gns3.com/docs/getting-started/installation/linux/, https://medium.com/@Ninja/install-gns3-on-arch-manjaro-linux-the-right-way-c5a3c4fa337d)
echo -e '\e[0;92m\nInstalling program GNS3, wait for completion.\e[0m'
sleep 3
yay --noconfirm -S qemu vpcs dynamips libvirt 
yay --noconfirm -S gns3-server gns3-gui 

sudo usermod -aG sysadmin kvm libvirt docker ubridge wireshark


#yay -S python-pypi2pkgbuild --noconfirm
#alias pypi2pkgalias='PKGEXT=.pkg.tar pypi2pkgbuild.py -g cython -b /tmp/pypi2pkgbuild/ -f'
#sudo pacman --noconfirm -S qt5-svg qt5-websockets python-pip python-pyqt5 python-sip
#mkdir -p $HOME/GNS3-Dev && cd $_
#gns3 server
#git clone https://github.com/GNS3/gns3-server.git
#cd gns3-server
#git tag --list 'v2.1.*'
#git checkout v2.1.12
#pypi2pkgalias git+file://$PWD
#cd /home/sysadmin
#gns3 gui
#git clone https://github.com/GNS3/gns3-gui.git
#cd gns3-gui
#git tag --list 'v2.1.*'
#git checkout v2.1.12
#pypi2pkgalias git+file://$PWD
#verify
#pacman -Qe | grep gns3
#python-gns3-gui-git 2.1.12.r0.ga1496bff-1
#python-gns3-server-git 2.1.12.r0.gbccdfc97-1



# Uprava konfigurace (https://docs.gns3.com/docs/troubleshooting-faq/troubleshoot-gns3/)
mkdir -p $HOME/.config/GNS3/2.2/
#/usr/bin/gns3server
sh -c 'echo "[Server]
path = /usr/bin/gns3server
ubridge_path = ubridge
host = localhost
port = 3080
images_path = /home/sysadmin/GNS3/images
projects_path = /home/sysadmin/GNS3/projects
appliances_path = /home/sysadmin/GNS3/appliances
additional_images_paths = 
symbols_path = /home/sysadmin/GNS3/symbols
configs_path = /home/sysadmin/GNS3/configs
report_errors = True
auto_start = True
allow_console_from_anywhere = False
auth = True
user = sysadmin
password = Netlab!23
protocol = http
console_start_port_range = 5000
console_end_port_range = 10000
udp_start_port_range = 10000
udp_end_port_range = 20000
[Qemu]
enable_kvm = false" > $HOME/.config/GNS3/2.2/gns3_server.conf'

echo -e '\e[0;92m\nInstallation GNS3 is completed.\e[0m'
sleep 3


# Install Docker (https://docs.docker.com/engine/install/ubuntu/)
echo -e '\e[0;92m\nInstalling Docker, wait for completion.\e[0m'
sleep 3
sudo pacman --noconfirm -S gnome-terminal
cd /home/sysadmin/downloads/
wget --no-check-certificate 'https://desktop.docker.com/linux/main/amd64/docker-desktop-4.17.0-x86_64.pkg.tar.zst?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-linux-amd64'
sudo pacman -U ./docker-desktop-4.17.0-x86_64.pkg.tar.zst
cd /home/sysadmin/
docker compose version
    
# Set up the repository

sudo pacman --noconfirm -Sy \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
    
# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
# Set up the stable repository
#sudo sh -c 'echo \
 # "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  #$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null'
     
# Install Docker Engine
sudo pacman -Sy
sudo systemctl enable docker.service
sudo systemctl start docker.service
# Add your user to the docker group
sudo usermod -aG docker sysadmin

# Install Portainer
sudo docker pull portainer/portainer-ce:latest
sudo docker run -d \
  --name portainer \
  --restart always \
  --publish 9443:9443 \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --volume portainer_data:/data portainer/portainer-ce:latest

# Install Watchtower
sudo docker pull containrrr/watchtower
sudo docker run -d \
  --name watchtower \
  --restart always \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower

echo -e '\e[0;92m\nInstallation Docker is completed.\e[0m'
sleep 3


# Install LXD
echo -e '\e[0;92m\nInstalling LXD, wait for completion.\e[0m'

sudo --noconfirm -S lxd arch-install-scripts
# Add your user to the lxd group
sudo adduser sysadmin lxd

sh -c 'echo "
config: {}
networks:
- config:
    ipv4.address: 10.20.30.1/24
    ipv4.nat: "true"
    ipv6.address: 2001:db8:acad::1/64
    ipv6.nat: "true"
  description: ""
  name: lxdbr0
  type: ""
  project: default
storage_pools:
- config:
    size: 36GB
  description: ""
  name: lxdstorage
  driver: btrfs
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      network: lxdbr0
      type: nic
    root:
      path: /
      pool: lxdstorage
      type: disk
  name: default
projects: []
cluster: null
" > $HOME/input.yaml'

sudo lxd init --preseed < $HOME/input.yaml
rm $HOME/input.yaml
    
# Create container
NAME="server"
echo -e '\e[0;92m\nDeploying container '$NAME' ...\e[0m'
sleep 3
lxc launch ubuntu:lts $NAME

# Add user to container
lxc exec $NAME -- groupadd sysadmin
lxc exec $NAME -- useradd -rm -d /home/sysadmin -s /bin/bash -g sysadmin -G sudo -u 1000 sysadmin
lxc exec $NAME -- sh -c 'echo "sysadmin:Netlab!23" | chpasswd'

# Enable SSH Password Authentication
lxc exec $NAME -- sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
lxc exec $NAME -- systemctl restart sshd

# Add static IP adress
sudo lxc stop $NAME
sudo lxc network attach lxdbr0 $NAME eth0 eth0
sudo lxc config device set $NAME eth0 ipv4.address 10.20.30.40
sudo lxc network set lxdbr0 ipv6.dhcp.stateful true
sudo lxc config device set $NAME eth0 ipv6.address 2001:db8:acad::40
sudo lxc start $NAME
sleep 3

echo -e '\e[0;92m\nConteiner '$NAME' is ready.\nInstallation LXD is completed.\e[0m'
sudo systemctl enable docker.service
sudo systemctl start docker.service

# clean & restart
echo -e '\e[0;92m\nCleaning ...\e[0m'
sleep 3
sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove -y
unset DEBIAN_FRONTEND

echo -e '\n\e[1;92m\nInstallation is completed, restarting PC!\e[0m'
sleep 3
sudo reboot


# Post-autoinstall
# ================
# Set Background
# Set Homepage (www.eduxo.cz)
# Set GNS3


