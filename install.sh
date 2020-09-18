#!/usr/bin/env bash
#  Copyright (c) 2018-2020. Prasad Tengse
#

# Installs dotfiles
# Probably this script is shitty and  specific to my setup.
# More generic solutions would be to use one of the tools mentioned in.
# https://wiki.archlinux.org/index.php/Dotfiles#Tools
# But most of them require Perl or python. Though
# most systems have those installed by default, I wanted something
# which was dependent only on bash/zsh

set -o pipefail

#Constants
readonly SCRIPT=$(basename "$0")
readonly YELLOW=$'\e[33m'
readonly GREEN=$'\e[32m'
readonly RED=$'\e[31m'
readonly BLUE=$'\e[34m'
readonly NC=$'\e[0m'
readonly CURDIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
readonly spacing_string="%+11s"

# Define direnv and antibody versions
readonly ANTIBODY_VERSION="6.1.1"
readonly DIRENV_VERSION="2.20.0"


readonly LOGO="   [0;1;31;91m_[0;1;33;93m__[0m       [0;1;35;95m_[0;1;31;91m_[0m  [0;1;33;93m_[0;1;32;92m__[0;1;36;96m__[0m [0;1;34;94m_[0;1;35;95m_[0m
  [0;1;33;93m/[0m [0;1;32;92m_[0m [0;1;36;96m\_[0;1;34;94m__[0m  [0;1;31;91m/[0m [0;1;33;93m/_[0;1;32;92m/[0m [0;1;36;96m__[0;1;34;94m(_[0;1;35;95m)[0m [0;1;31;91m/_[0;1;33;93m_[0m [0;1;32;92m__[0;1;36;96m_[0m
 [0;1;33;93m/[0m [0;1;32;92m/[0;1;36;96m/[0m [0;1;34;94m/[0m [0;1;35;95m_[0m [0;1;31;91m\/[0m [0;1;33;93m_[0;1;32;92m_/[0m [0;1;36;96m_[0;1;34;94m//[0m [0;1;35;95m/[0m [0;1;31;91m/[0m [0;1;33;93m-[0;1;32;92m_|[0;1;36;96m_-[0;1;34;94m<[0m
[0;1;32;92m/_[0;1;36;96m__[0;1;34;94m_/[0;1;35;95m\_[0;1;31;91m__[0;1;33;93m/\[0;1;32;92m__[0;1;36;96m/_[0;1;34;94m/[0m [0;1;35;95m/_[0;1;31;91m/_[0;1;33;93m/\[0;1;32;92m__[0;1;36;96m/_[0;1;34;94m__[0;1;35;95m/[0m
"

function display_usage()
{
#Prints out help menu
cat <<EOF
$LOGO
Usage: ${GREEN}${SCRIPT} ${BLUE}  [options]${NC}
---------------------------------------------
[-i --install]         [Install dotfiles]
[-f --no-fonts]        [Do not install fonts]
[-c --no-config]       [Skip Configs in config]
[-C --only-config]     [Only install config files]
[-e --no-extra-config] [Skip extra config mainly UI, IDE stuff
                        Useful for no GUI or servers]
[-x --default-name]    [Fallback to default config name]
[-t --no-templates]    [Skip instaling Templates]
[-m --minimal]         [Only install git, bash, gpg config]
[-n --name]            [Name of the config]
[-z --install-zsh]     [Include ZSH config]

[--tools]              [Install direnv, starship and antibody]
[-Z --only-zsh]        [Only Install ZSH config]
[-h --help]            [Display this help message]
[-v --version]         [Display version info]

${YELLOW}Notes on --name parameter${NC}
---------------------------------------------
* If a config specific file or directory is not found,
  It is,
    a] Skiped for Git, GNUPG, BASH
    b] Default is used for configs
    c] Fonts and Templates are common for all
${YELLOW}* If -x or --default-name parameter is used, name parameter is
  ignored.

${YELLOW}Notes on file removal/rename${NC}
--------------------------------------------
* If files are deleted/renamed in this repo, symlinks might become broken
. In such cases remove the broken symlinks manually
 or install the files again or both.

Github repo link : ${BLUE}https://github.com/tprasadtp/dotfiles${NC}
EOF
}

function print_info()
{
  printf "➜ %s \n" "$@"
}

function print_success()
{
  printf "%s✔ %s %s\n" "${GREEN}" "$@" "${NC}"
}

function print_warning()
{
  printf "%s⚠ %s %s\n" "${YELLOW}" "$@" "${NC}"
}

function print_error()
{
   printf "%s✖ %s %s\n" "${RED}" "$@" "${NC}"
}

function print_notice()
{
  printf "%s✦ %s %s\n" "${BLUE}" "$@" "${NC}"
}

function print_step()
{
  printf "  - %s\n" "$@"
}

function display_version()
{
  # shellcheck disable=SC2059
  printf "${spacing_string} ${YELLOW} ${SCRIPT} ${NC}\n${spacing_string} ${YELLOW} ${VERSION} ${NC}\n" "Executable:" "Version:";
}


function __link_files()
{
  # Liks files inside a directory to specified destination
  # Arg-1 Input directory
  # Arg 2 Output dir to place symlinks
  # Always .md .git .travis.yml are ignored.
  # This operation is NOT recursive.

  local src="${1}"
  local dest="${2}"

#  echo "SRC : $src"
#  echo "DEST: $dest"
#  echo "CURDIR : $CURDIR"

  if [ -d "${CURDIR}/${src}" ]; then
    if mkdir -p "${INSTALL_PREFIX}/${dest}"; then
      while IFS= read -r -d '' file
      do
        f="$(basename "$file")"
        if ln -sfn "$file" "${INSTALL_PREFIX}/${dest}/${f}"; then
          print_success "Linked : ${f}"
        else
          print_error "Linking ${f} failed!"
        fi
      done< <(find "$CURDIR/${src}" -maxdepth 1  -not -name "$(basename "$src")" -not -name '*.md' -not -name '.travis.yml' -not -name '.git' -not -name 'LICENSE'  -not -name '.editorconfig' -print0)
    else
      print_error "Failed to create destination : $dest"
    fi # mkdir
    else
      print_error "Directory ${src} not found!"
  fi # src check

}


function __link_file()
{
  # Liks file to specified destination
  # Arg-1 Input File
  # Arg 2 Output symlink

  local src="${1}"
	local dest_dir
	dest_dir="$(dirname "${INSTALL_PREFIX}/${2}")"
	local skip_base_dir_create="${3:-false}"

#	 echo "${skip_base_dir}"
#  echo "SRC : $src"
#  echo "DEST: $dest"
#  echo "CURDIR : $CURDIR"

  if [ -f "${CURDIR}/${src}" ]; then
		if [[ ${skip_base_dir_create} != "true" ]]; then

			if mkdir -p "${dest_dir}"; then
				f="$(basename "$src")"
				if ln -sfn "${CURDIR}/${src}" "${dest_dir}/${f}"; then
					print_success "Linked : ${f}"
				else
					print_error "Linking ${f} failed!"
					fi
			else
				print_error "Failed to create destination : $dest_dir"
			fi # mkdir

		# do not create base dir
		else
			print_info "Assuming ${dest_dir} already exists"

			f="$(basename "$src")"
			if ln -sfn "${CURDIR}/${src}" "${dest_dir}/${f}"; then
				print_success "Linked : ${f}"
			else
				print_error "Linking ${f} failed!"
			fi
		fi # base dir create flag

    else
      print_error "File ${src} not found!"
  fi # src check

}


function minimal_install()
{
    # Installs only minimal dotfiles
    # git, zsh, bash and gpg
    # Rest all files are ignored.

    # .bash_profile
		print_info "Installing .bash_profile"
		__link_file "bash/.bash_profile" ".bash_profile" "true"

    # Git
    # First check for config specific directory
    if [[ -d $CURDIR/git/$config_name ]] && [[ -f $CURDIR/git/$config_name/.gitconfig ]];then
      print_info "GIT Profile : ${config_name}"
      __link_file "git/$config_name/.gitconfig" ".gitconfig" "true"
    else
      print_error "GIT    :  No config found!"
    fi

    # Bash
    # First check for config specific directory
    if [[ -d $CURDIR/bash/$config_name ]];then
      print_info "BASH Profile : ${config_name}"
      __link_files "bash/${config_name}" ""
    # If no config specific dirs are found, use default `bash`
    else
      print_error "BASH   :  No config found!"
    fi

    # GPG
    # First check for config specific directory
    if [[ -d $CURDIR/gnupg/${config_name} ]];then
      print_info "GNUPG  Profile : ${config_name}"
      __link_files "gnupg/$config_name" ".gnupg/"
    # If no config specific dirs are found, use default `gnupg`
    else
      print_error "GNUPG  : No config found!"
    fi

		if [[ ${minimal_install} == "true" ]]; then
			__install_config_files "starship" ".config"
		fi

}


function install_fonts()
{
  print_info "Installing fonts..."
  if mkdir -p "$INSTALL_PREFIX"/.local/share; then
	  if ln -snf "$CURDIR"/fonts "$INSTALL_PREFIX"/.local/share/fonts; then
      print_success "Fonts installed successfully!"
      if [[ $clear_font_cache == "true" ]]; then
        print_info "Clearing font cache..."
        print_warning "Please enter root/sudo password when requested."
        sudo fc-cache -f  || print_error "Failed to clear font cache!"
      fi
    else
      print_error "Failed to link fonts to .local/share/fonts"
    fi
  else
    print_error "Failed to create fonts directory. Fonts will not be linked!"
  fi
}


function install_templates()
{
  print_info "Installing templates..."
  if mkdir -p "${INSTALL_PREFIX}"/Templates; then
    __link_files "templates" "Templates"
  else
    print_error "Failed to create ~/Templates directory. Templates will not be installed"
  fi
}


function __install_config_files()
{
  if [[ $# -lt 2 ]]; then
    print_error "Invalid number of arguments "
    exit 21;
  fi

  cfg_dir="$1"
  dest_dir="$2"

  # First check for config specific directory
  if [[ -d $CURDIR/config/$cfg_dir-$config_name ]];then
    print_notice "Using config/${cfg_dir} (${config_name})"

    cfg_dir="${cfg_dir}-${config_name}"
  # If no config specific dirs are found, use default config
  elif [[ -d $CURDIR/config/$cfg_dir ]];then
    print_notice "Using config/${cfg_dir} (default)"
  else
    print_error "No configs found for ${cfg_dir}"
    exit 21
  fi


  if mkdir -p "$INSTALL_PREFIX"/"$dest_dir"; then
    # destination path is prefixed with INSTALL_PREFIX automatically
    __link_files "config/$cfg_dir" "$dest_dir"
  else
    print_error "Failed to create $dest_dir directory."
    print_error "$cfg_dir will not be installed!"
  fi
}


function install_config_files()
{
  # Installs files in config to .config
  # Easy way clould be to use gnu stow.
  # But Its not installed by default.

  # Neofetch
  __install_config_files "neofetch" ".config/neofetch"

  # Docker
  __install_config_files "docker" ".docker"

  # Starship
  __install_config_files "starship" ".config"

  # Direnv
  __install_config_files "direnv" ".config/direnv"

  if [[ ${skip_extra_config} == "true" ]];then
    print_info "Skipping extra configs (fonts, extra utils and GUI stuff)"
  else
    #
    # VS code [Mainly Telemetry stuff]
    __install_config_files "vscode" ".config/Code/User"
    __install_config_files "fonts" ""
    __install_config_files "npm" ""

		# Cobra
    __install_config_files "cobra" ""

    # Poetry
    __install_config_files "pypoetry" ".config/pypoetry"

		# GNU Radio
		__install_config_files "gnuradio" ".gnuradio"

		# Tilix
		__install_config_files "tilix" ".config/tilix/schemes"

		# MPV
		__install_config_files "mpv" ".config/mpv"

  fi
}


function install_zsh()
{
  if [[ -d $CURDIR/zsh/$config_name.zshrc ]]; then
    print_info "Will use $config_name.zshrc (in zsh)"

    print_notice "Installing base configs"
    print_info "Installing custom plugins"
    __link_files "zsh/plugins" ".zsh/plugins"

		# Antibody and zshrc
    print_info "Installing $config_name antibody"
    __link_file "zsh/${config_name}.zshrc/.antibodyrc" ".zsh/.antibodyrc"

    # Now install core zshrc
    print_info "Installing $config_name zshrc"
		__link_file "zsh/${config_name}.zshrc/.zshrc" ".zshrc" "true"

  else
    print_error "cannot find ZSH profile ${config_name} in zsh"
  fi

}


function install_vim()
{

	if [[ -d $CURDIR/vim ]]; then
		print_info "Installing VIM config"

		print_info "Installing Autoload + Manager"
		__link_file "vim/autoload/plug.vim" ".local/share/nvim/site/autoload/plug.vim"
		print_info "Installing config"
		__link_file "vim/init.vim" ".config/nvim/init.vim"
	else
		print_error "vim configs not found!"
	fi

}


function install_tools()
{
		print_info "Installing Required Tools"
		mkdir -p "${INSTALL_PREFIX}/bin"
		mkdir -p vendor/tools

		print_info "Download and Install Starship"
		print_step "download binary"
		curl -sSfL https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz --output vendor/tools/starship.tar.gz
		print_step "fetch chevksum"
		curl -sSfL https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz.sha256 --output vendor/tools/starship.tar.gz.sha256
		print_step "verify checksum"
		echo "$(cat vendor/tools/starship.tar.gz.sha256) vendor/tools/starship.tar.gz" | sha256sum --quiet -c -
		print_step "install"
		tar xzf vendor/tools/starship.tar.gz -C "${INSTALL_PREFIX}/bin"

		print_info "Download and Install direnv"
		curl -sSfL "https://github.com/direnv/direnv/releases/download/v${DIRENV_VERSION}/direnv.linux-amd64" -o "${INSTALL_PREFIX}/bin/direnv"

		print_info "Download and Install antibody"
		print_step "download binary"
		curl -sSfL "https://github.com/getantibody/antibody/releases/download/v${ANTIBODY_VERSION}/antibody_Linux_x86_64.tar.gz" --output vendor/tools/antibody_Linux_x86_64.tar.gz
		print_step "get checksum"
		curl -sSfL "https://github.com/getantibody/antibody/releases/download/v${ANTIBODY_VERSION}/antibody_${ANTIBODY_VERSION}"_checksums.txt  --output vendor/tools/antibody_"${ANTIBODY_VERSION}"_checksums.txt
		print_step "verify checksum"
		(cd vendor/tools/ && sha256sum -c --ignore-missing "antibody_${ANTIBODY_VERSION}_checksums.txt")
		print_step "install"
		tar --extract --gzip --file=vendor/tools/antibody_Linux_x86_64.tar.gz --directory="${INSTALL_PREFIX}/bin" antibody


		print_info "Set Permissions"
		print_step "direnv"
		chmod 700 "${INSTALL_PREFIX}/bin/direnv"
		print_step "starship"
		chmod 700 "${INSTALL_PREFIX}/bin/starship"
		print_step "antibody"
		chmod 700 "${INSTALL_PREFIX}/bin/antibody"
}

function main()
{
  #check if no args
	if [[ ${CODESPACES} == "true" ]]; then
		print_warning "Invoking codespaces Install"
		action_install="codespaces"
	else
		if [ $# -lt 1 ]; then
			print_error "No arguments/Invalid number of arguments See usage below."
			display_usage;
			exit 1;
		fi
	fi

  INSTALL_PREFIX="${HOME}"

  while [ "${1}" != "" ]; do
    case ${1} in
      -i | --install )      action_install="regular"
                            ;;
      -n | --name )         shift;
                            config_name="${1}";
                            ;;
      -h | --help )         display_usage;
                            exit $?
                            ;;
      -f | --no-fonts)      skip_fonts="true";
                            ;;
      -x | --default-name)  use_default_name="true"
                            ;;
      -t | --install-templates)  bool_install_templates="true";
                            ;;
      -m | --minimal)       minimal_install="true";
                            ;;
			--codespaces)       	action_install="codespaces";;
      --version)            display_version;
                            exit $?;
                            ;;
			--tools)              install_tools;
														exit $?;;
      -C | --only-config)   only_config="true";
                            ;;
      -c | --no-config)     skip_config="true";
                            ;;
      -e | --no-extra-config) skip_extra_config="true";
                            ;;
      --clear-font-cache)   readonly clear_font_cache="true";
                            ;;
      -z | --install-zsh)   readonly install_zsh="true";
														;;
      -Z | --only-zsh)      readonly bool_only_zsh="true"
                            ;;
      -v | --install-vim)   readonly bool_install_vim="true";
														;;
      -V | --only-vim)      readonly bool_only_vim="true"
                            ;;
      -T | --test-mode)     INSTALL_PREFIX="${HOME}/Junk";
                            print_warning "Test mode is active!";
                            print_warning "Files will be installed to ${INSTALL_PREFIX}";
                            mkdir -p "${INSTALL_PREFIX}" || exit 31
                            ;;
      * )                   print_error "Invalid argument(s). See usage below."
                            usage;
                            exit 1
                            ;;
    esac
    shift
  done


	if [[ $action_install == "codespaces" ]]; then

	  config_name="sindhu"

		# Neofetch
		print_info "Installing Config"
		__install_config_files "neofetch" ".config/neofetch"

		# Docker
		__install_config_files "docker" ".docker"

		# Starship
		__install_config_files "starship" ".config"

		# Direnv
		__install_config_files "direnv" ".config/direnv"

		# VS Code
		__install_config_files "vscode" ".config/Code/User"

		# Tools
		install_tools

		# ZSH
		install_zsh

		# Fonts
		install_fonts

		minimal_install


  elif [[ $action_install == "regular" ]]; then

    if [[ $use_default_name == "true" ]]; then
      config_name="sindhu";
      print_info "Using default config name";
    fi

    if [[ $only_config == "true" ]]; then
      if [[ $skip_config == "true" ]]; then
        print_error "Option conflicts!"
        exit 1
      fi
      print_notice "Only config files will be installed."
      install_config_files
      exit $?
    fi

    # Check if config name is empty
    if [[ $config_name == "" ]]; then
      print_error "No config name specified"
      exit 10
    fi

    if [[ $bool_only_zsh ]]; then
      print_notice "Only ZSH will be installed"
      install_zsh
      exit $?
    fi

    if [[ $bool_only_vim ]]; then
      print_notice "Only VIM config will be installed"
      install_vim
      exit $?
    fi

    # Minimal checks
    if [[ ${minimal_install} == "true" ]]; then
      print_notice "Minimal install is set to True."
      minimal_install;
    else

      minimal_install;
      # check templates
      if [[ $bool_install_templates == "true" ]]; then
				install_templates;
      else
        print_notice "Skipping templates installation"
      fi

      # check fonts
      if [[ $skip_fonts == "true" ]]; then
        print_notice "Skipping fonts installation"
      else
        install_fonts;
      fi

      #check config skip flag
      if [[ $skip_config == "true" ]]; then
        print_notice ".config files will not be installed."
      else
        print_info "Installing config files..."
        install_config_files
      fi

			# zsh
			if [[ $install_zsh == "true" ]]; then
				install_zsh
			else
				print_info "Skipping zsh install"
			fi

			# vim
			if [[ $bool_install_vim == "true" ]]; then
				install_vim
			else
				print_info "Skipping vim-config install"
			fi

    fi # end of minimal if

  else
    print_error "Did you forget to pass -i | --install or --codespaces?"
    exit 10
  fi

}

#
main "$@"
