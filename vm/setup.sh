#!/bin/bash

function packages()
{
echo "Install Basics"
sudo apt-get install -y curl \
    wget \
    iputils-ping \
    htop \
    shellcheck \
    tilix
}


function install_tilix()
{
	echo "Getting Tilix"
	curl -SsfLO https://raw.githubusercontent.com/tprasadtp/dotfiles/master/config/tilix/gruvbox-dark-hard.json

 echo "Installing Tilix"
  mkdir -p $HOME/.config/tilix/schemes
  install -o $USER -g "$USER" -m 600 gruvbox-dark-hard.json $HOME/.config/tilix/schemes/gruvbox-dark-hard.json

}

function install_font()
{
	echo "Getting Font"
	curl -SsfL "https://github.com/tprasadtp/dotfiles/blob/master/fonts/StarshipCode.ttf?raw=true" -o StarshipCode.ttf

  echo "Installing Font"
  mkdir -p $HOME/.local/share/fonts
  install -o $USER -g "$USER" -m 600 StarshipCode.ttf $HOME/.local/share/fonts/StarshipCode.ttf

}

function install_sudo_lecture()
{

	echo "Get Sudo Lecture"
	mkdir -p ./sudo
	curl -SsfLO https://raw.githubusercontent.com/tprasadtp/dotfiles/master/system/sudo/lecture
	curl -SsfLO https://raw.githubusercontent.com/tprasadtp/dotfiles/master/system/sudo/sudo.lecture

	echo "Install Sudo Lecture"
  install -g root -o root -m 640 sudo.lecture /etc/sudoers.d/sudo.lecture
	install -g root -o root -m 640 lecture /etc/sudoers.d/lecture
}


function usage()
{
cat <<EOF
      -p)      packages;;
      -t)      install_tilix;;
      -s)      install_sudo_lecture;;
      -v)      setup_vpn;;
      -m)      setup_fstab;;
			-h)      usage;exit 0;;
EOF
}

function setup_fstab()
{
    echo "Mount: Parent dirs"
    sudo mkdir -p /media/$USER/host
    echo "Mount: Permission"
    sudo chown $USER:$USER /media/$USER/host
    sudo chmod 700 /media/$USER/host
    echo "Mount: FStab"
		if ! grep -q vm /etc/fstab; then
			echo "No Host fstab Entry! Adding a new one"
	    echo "vm   /media/$USER/host   9p  trans=virtio    0   0" | sudo tee -a /etc/fstab
		fi
}


function setup_vpn()
{
sudo apt-get install -y \
    openvpn \
    dialog \
    python3-pip \
    python3-setuptools
sudo pip3 install protonvpn-cli
sudo tee /etc/systemd/system/protonvpn.service <<EOT
[Unit]
Description=ProtonVPN
Wants=network-online.target

[Service]
Type=forking
Environment=SUDO_USER=$USER
ExecStart=/usr/local/bin/protonvpn c --cc NL
ExecReload=/usr/local/bin/protonvpn c --cc NL
ExecStop=/usr/local/bin/protonvpn disconnect
Restart=always

[Install]
WantedBy=multi-user.target
EOT

sudo systemctl daemon-reload
}


function fscrypt_setup()
{
	echo "fscrypt: Get Binaries"
	curl -fLO https://github.com/google/fscrypt/releases/download/v0.2.8/pam_fscrypt.so
	curl -fLO https://github.com/google/fscrypt/releases/download/v0.2.8/fscrypt
	echo "fscrypt: Install"
	install -g root -o root -m 755 fscrypt /usr/local/bin/fscrypt
	install -g root -o root -m 644 pam_fscrypt.so /usr/share/pam-config/pam_fscrypt.so
	sudo tee /usr/share/pam-config/fscrypt-keyring-fix << EOF
Name: Fscrypt Keyring Fix (Ubuntu)
Default: yes
Priority: 0
Session-Type: Additional
Session:
	optional	pam_keyinit.so force revoke
EOF
	sudo pam-auth-update
}

function main()
{
  #check if no args
  if [ $# -lt 1 ]; then
    echo "No arguments/Invalid number of arguments See usage below."
    exit 1;
  fi;


  while [ "${1}" != "" ]; do
    case ${1} in
      -p)      packages;;
      -t)      install_tilix;;
      -s)      install_sudo_lecture;;
      -v)      setup_vpn;;
      -m)      setup_fstab;;
			-h)      usage;exit 0;;
			-f)      fscrypt_setup;;
      * )      echo "Invalid argument(s)"
               exit 1
               ;;
    esac
    shift
  done
}

main "$@"
