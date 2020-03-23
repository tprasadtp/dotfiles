SHELL := /bin/bash

.DEFAULT_GOAL := help

# Set install prefix if not set already
INSTALL_PREFIX ?= $(HOME)

# Get directory of makefile without trailing slash
ROOT_DIR := $(patsubst %/, %, $(dir $(realpath $(firstword $(MAKEFILE_LIST)))))
HPC_REPO_DIR ?= $(ROOT_DIR)/../hpc-dotfiles

GITCOMMIT := $(shell git rev-parse --short HEAD)
GITUNTRACKEDCHANGES := $(shell git status --porcelain --untracked-files=no)
ifneq ($(GITUNTRACKEDCHANGES),)
	GITCOMMIT := $(GITCOMMIT)++
endif

.PHONY: test
test: shellcheck test-install-default  test-install-minimal ## Runs all the tests


.PHONY: shellcheck
shellcheck: ## Runs the shellcheck tests on the scripts.
	@bash ./tests/test-shell-scripts.sh

.PHONY: install
install: ## Installs default profile (bash, zsh, git, configs, fonts and templates)
	@bash ./install.sh -i -x -z

.PHONY: test-install-default
test-install-default: ## Test Installs default profile
	@bash ./install.sh -i -x -T -z -v -t

.PHONY: test-install-minimal
test-install-minimal: ## Tets Installs minimal profile
	@bash ./install.sh -i -T -e -c -f -n minimal

.PHONY: verify
verify: ## Verifies checksums
	@bash checksum.sh -v

.PHONY: verify-integrity
verify-integrity: ## Verifies checksums
	@bash checksum.sh -v -G

.PHONY: sign
sign: ## sign
	@bash checksum.sh -c -s -v


.PHONY: help
help: ## This help dialog.
	@IFS=$$'\n' ; \
    help_lines=(`fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##/:/'`); \
    printf "%-30s %s\n" "--------" "------------" ; \
	printf "%-30s %s\n" " Target " "    Help " ; \
    printf "%-30s %s\n" "--------" "------------" ; \
    for help_line in $${help_lines[@]}; do \
        IFS=$$':' ; \
        help_split=($$help_line) ; \
        help_command=`echo $${help_split[0]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
        help_info=`echo $${help_split[2]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
        printf '\033[92m'; \
        printf "%-30s %s" $$help_command ; \
        printf '\033[0m'; \
        printf "%s\n" $$help_info; \
    done


# This uses rsync to sync hpc and minimal profiles to hpc repo.
# also neofetch, starship and direnv configs are synced.
.PHONY: sync-hpc
sync-hpc: ## Syncs HPC dotfiles submodule with hpc profiles from this repo.
	@echo -e "\033[1;92m➜ $@ \033[0m"
	@echo -e "\033[34m‣ syncing profiles\033[0m"

	@echo -e "\033[33m  - common bash files\033[0m"
	@cp --preserve --force $(ROOT_DIR)/bash/.bash_profile $(HPC_REPO_DIR)/bash/.bash_profile
	@echo -e "\033[33m  - bash hpc profile\033[0m"
	@rsync --checksum --copy-unsafe-links --perms --executability --times --recursive --delete  $(ROOT_DIR)/bash/hpc/ $(HPC_REPO_DIR)/bash/hpc/
	@echo -e "\033[33m  - bash minimal profile\033[0m"
	@rsync --checksum --copy-unsafe-links --perms --executability --times --recursive --delete  $(ROOT_DIR)/bash/minimal/ $(HPC_REPO_DIR)/bash/minimal/

	@echo -e "\033[33m  - git hpc profile\033[0m"
	@rsync --checksum --copy-unsafe-links --perms --executability --times --recursive --delete  $(ROOT_DIR)/git/hpc/ $(HPC_REPO_DIR)/git/hpc/

	@echo -e "\033[33m  - gnupg hpc profile\033[0m"
	@rsync --checksum --copy-unsafe-links --perms --executability --times --recursive --delete  $(ROOT_DIR)/gnupg/hpc/ $(HPC_REPO_DIR)/gnupg/hpc/

	@echo -e "\033[34m‣ syncing configs\033[0m"
	@echo -e "\033[33m  - starship\033[0m"
	@rsync --checksum --copy-unsafe-links --perms --executability --times --recursive --delete  $(ROOT_DIR)/config/starship/ $(HPC_REPO_DIR)/config/starship
	@echo -e "\033[33m  - direnv\033[0m"
	@rsync --checksum --copy-unsafe-links --perms --executability --times --recursive --delete  $(ROOT_DIR)/config/direnv/ $(HPC_REPO_DIR)/config/direnv

	@echo -e "\033[34m‣ syncing meta\033[0m"
	@echo -e "\033[33m  - LICENSE\033[0m"
	@cp --preserve --force $(ROOT_DIR)/LICENSE.md $(HPC_REPO_DIR)/LICENSE.md
	@echo -e "\033[33m  - .gitignore\033[0m"
	@cp --preserve --force $(ROOT_DIR)/.gitignore $(HPC_REPO_DIR)/.gitignore
	@echo -e "\033[33m  - .editorconfig\033[0m"
	@echo -e "\033[33m  - signer\033[0m"
	@cp --preserve --force $(ROOT_DIR)/checksum.sh $(HPC_REPO_DIR)/checksum.sh
	@cp --preserve --force $(ROOT_DIR)/.editorconfig $(HPC_REPO_DIR)/.editorconfig
	@echo -e "\033[33m  - testing scripts\033[0m"
	@rsync --checksum --copy-unsafe-links --perms --executability --times --recursive --delete  $(ROOT_DIR)/tests/ $(HPC_REPO_DIR)/tests
	@echo -e "\033[33m  - ci-config\033[0m"
	@rsync --checksum --copy-unsafe-links --perms --executability --times --recursive --delete  --exclude='sync-hpc.yml'  $(ROOT_DIR)/.github/ $(HPC_REPO_DIR)/.github

	@echo -e "\033[33m  - copy reference\033[0m"
	@echo "tprasadtp/dotfiles@$(GITCOMMIT)" > $(HPC_REPO_DIR)/.upstream

.PHONY: install-tools
install-tools: ## Installs extra tools used by dotfiles (starship-rs and direnv)
	@echo -e "\033[1;92m➜ $@ \033[0m"
	@echo -e "\033[34m‣ downloading starship-prompt\033[0m"
	@mkdir -p $(ROOT_DIR)/vendor/tools
	@echo -e "\033[33m  - download binary\033[0m"
	@curl -sL https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz --output $(ROOT_DIR)/vendor/tools/starship.tar.gz
	@echo -e "\033[33m  - download checksum\033[0m"
	@curl -sL https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz.sha256 --output $(ROOT_DIR)/vendor/tools/starship.tar.gz.sha256
	@echo -e "\033[33m  - verify checksum\033[0m"
	@echo "$$(cat $(ROOT_DIR)/vendor/tools/starship.tar.gz.sha256) $(ROOT_DIR)/vendor/tools/starship.tar.gz" | sha256sum --quiet -c -
	@echo -e "\033[33m  - install\033[0m"
	@mkdir -p $(INSTALL_PREFIX)/bin
	@tar xzf $(ROOT_DIR)/vendor/tools/starship.tar.gz -C $(INSTALL_PREFIX)/bin

	@echo -e "\033[34m‣ downloading direnv\033[0m"
	@echo -e "\033[33m  - download & install binary\033[0m"
	@mkdir -p $(INSTALL_PREFIX)/bin
	@curl -sL https://github.com/direnv/direnv/releases/download/v2.20.0/direnv.linux-amd64 -o $(INSTALL_PREFIX)/bin/direnv

	@echo -e "\033[34m‣ set permissions\033[0m"
	@echo -e "\033[33m  - on bin\033[0m"
	@chmod 700 $(INSTALL_PREFIX)/bin
	@echo -e "\033[33m  - on direnv\033[0m"
	@chmod 700 $(INSTALL_PREFIX)/bin/direnv
	@echo -e "\033[33m  - on starship\033[0m"
	@chmod 700 $(INSTALL_PREFIX)/bin/starship

.PHONY: update-vim-plug
update-vim-plug: ## updates vim-plug(not plugins)
	@echo -e "\033[1;92m➜ $@ \033[0m"
	@mkdir -p $(ROOT_DIR)/vim/vim-plug $(ROOT_DIR)/vendor/source
	curl -sSfL -o $(ROOT_DIR)/vendor/source/vim-plug.json https://api.github.com/repos/junegunn/vim-plug/commits/master
	curl -sSfL -o $(ROOT_DIR)/vim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim


.PHONY: update-metadta
update-metadata: ## update medatata-hashes
	@echo -e "\033[1;92m➜ $@ \033[0m"
	vimplug_chash="$$(jq -r '.sha' $(ROOT_DIR)/vendor/source/vim-plug.json)";\
		__vimplug_cdate="$$(jq -r ".commit.committer.date" $(ROOT_DIR)/vendor/source/vim-plug.json)";\
		vimplug_cdate=`date --date "$${__vimplug_cdate}" "+%b-%d-%Y" `;\
		echo "{\"vimplug\": {\"commit\": \"$${vimplug_chash:0:7}\", \"sha1\": \"$${vimplug_chash}\", \"date\": \"$${vimplug_cdate}\"}}" | tee $(ROOT_DIR)/vendor/vendor.json


.PHONY: clean-downloads
clean-downloads: ## cleanup old downloads
	@rm -f vendor/{source,tools}/*.*

.PHONY: debug-vars
debug-vars:
	@echo "ROOT_DIR: $(ROOT_DIR)"
	@echo "INSTALL_PREFIX: $(INSTALL_PREFIX)"
	@echo "HPC_REPO_DIR: $(HPC_REPO_DIR)"
	@echo "XDG_CONFIG_HOME: $(XDG_CONFIG_HOME)"

.PHONY: install-system
install-system: ## Install system mods (Requires Root)
	@echo "Installing Sudo Lecture"
	install -g root -o root -m 640 $(ROOT_DIR)/system/sudo/sudo.lecture /etc/sudoers.d/sudo.lecture
	install -g root -o root -m 640 $(ROOT_DIR)/system/sudo/lecture /etc/sudoers.d/lecture
