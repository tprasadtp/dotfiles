#!/bin/bash

readonly SCRIPT=$(basename "$0")

function packages()
{
echo "Install Basics"
sudo apt-get install -y curl \
    wget \
    iputils-ping \
    htop \
    whiptail \
    shellcheck \
    openvpn \
    dialog \
    python3-pip \
    python3-setuptools
}



function usage()
{
cat <<EOF

# $SCRIPT [options]

[-p --pkg]    Packages
[-v --vpn]    Proton VPN
[-m --mount]  Mounting Host via plan9
[-h --help]   This Help Message
EOF
}

function setup_fstab()
{
    echo "Parent dirs"
    sudo mkdir -p /mnt/host
    echo "Permission"
    sudo chown "$USER":"$USER" /mnt/host
    chmod 700 /mnt/host
    echo "Mounts via fstab"
    echo "vm   /mnt/host    9p  trans=virtio    0   0" | sudo tee -a /etc/fstab
}

function setup_fscrypt()
{
echo "Download"
sudo curl -sSfL https://github.com/google/fscrypt/releases/download/v0.2.9/fscrypt -o /usr/local/bin/fscrypt
sudo curl -sSfL  https://github.com/google/fscrypt/releases/download/v0.2.9/pam_fscrypt.so -o /usr/local/lib/security/pam_fscrypt.so
echo "Install PAM Configs"
sudo tee /usr/share/pam-configs/fscrypt-pam <<EOT
Name: fscrypt-pam
Default: yes
Priority: 0
Auth-Type: Additional
Auth-Final:
	optional	/usr/local/lib/security/pam_fscrypt.so
Session-Type: Additional
Session-Interactive-Only: yes
Session-Final:
	optional	/usr/local/lib/security/pam_fscrypt.so drop_caches lock_policies
Password-Type: Additional
Password-Final:
	optional	/usr/local/lib/security/pam_fscrypt.so
EOT
echo "Enable PAM Modules"
sudo pam-auth-update --enable fscrypt-pam
}

function setup_vpn()
{
sudo -H pip3 install protonvpn-cli
sudo tee /etc/systemd/system/protonvpn.service <<EOT
[Unit]
Description=ProtonVPN
Wants=network-online.target

[Service]
Type=forking
Environment=SUDO_USER=$USER
ExecStart=/usr/local/bin/protonvpn c --cc NL -p udp
ExecReload=/usr/local/bin/protonvpn c --cc NL -p udp
ExecStop=/usr/local/bin/protonvpn disconnect
Restart=always

[Install]
WantedBy=multi-user.target
EOT

sudo systemctl daemon-reload
sudo systemctl enable protonvpn
}


function main()
{
  #check if no args
  if [ $# -lt 1 ]; then
    echo "No arguments/Invalid number of arguments See usage below."
    usage
    exit 1;
  fi;


  while [ "${1}" != "" ]; do
    case ${1} in
      -p | --pkg)      packages;;
      -v | --vpn)      setup_vpn;;
      -m | --mount)    setup_fstab;;
      -h | --help)     usage;exit 0;;
      * )      echo "Invalid argument(s)"
               exit 1
               ;;
    esac
    shift
  done
}

main "$@"
