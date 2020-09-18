SHELL := /bin/bash

.DEFAULT_GOAL := help

# Set install prefix if not set already
INSTALL_PREFIX ?= $(HOME)

# Get directory of makefile without trailing slash
ROOT_DIR := $(patsubst %/, %, $(dir $(realpath $(firstword $(MAKEFILE_LIST)))))
HPC_REPO_DIR ?= ../hpc-dotfiles

GITCOMMIT := $(shell git rev-parse --short HEAD)
GITUNTRACKEDCHANGES := $(shell git status --porcelain --untracked-files=no)
ifneq ($(GITUNTRACKEDCHANGES),)
	GITCOMMIT := $(GITCOMMIT)++
endif

.PHONY: test
test: shellcheck test-install-default  test-install-minimal ## Runs all the tests


.PHONY: shellcheck
shellcheck: ## Runs the shellcheck tests on the scripts.
	./tests/test-shell-scripts.sh

.PHONY: install
install: ## Installs default profile (bash, zsh, git, configs, fonts and templates)
	./install.sh -i -x -z

.PHONY: test-install-default
test-install-default: ## Test Installs default profile
	./install.sh -i -x -T -z -v -t

.PHONY: test-install-minimal
test-install-minimal: ## Test Install minimal profile
	./install.sh -i -T -e -c -f -n minimal

.PHONY: verify
verify: ## Verifies checksums
	./checksum.sh -v

.PHONY: sign
sign: ## Sign
	./checksum.sh -c -s -v

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
	@cp --preserve --force bash/.bash_profile $(HPC_REPO_DIR)/bash/.bash_profile
	@echo -e "\033[33m  - bash hpc profile\033[0m"
	@rsync --checksum --copy-unsafe-links --perms --executability --times --recursive --delete  bash/hpc/ $(HPC_REPO_DIR)/bash/hpc/
	@echo -e "\033[33m  - bash minimal profile\033[0m"
	@rsync --checksum --copy-unsafe-links --perms --executability --times --recursive --delete  bash/minimal/ $(HPC_REPO_DIR)/bash/minimal/

	@echo -e "\033[33m  - git hpc profile\033[0m"
	@rsync --checksum --copy-unsafe-links --perms --executability --times --recursive --delete  git/hpc/ $(HPC_REPO_DIR)/git/hpc/

	@echo -e "\033[33m  - gnupg hpc profile\033[0m"
	@rsync --checksum --copy-unsafe-links --perms --executability --times --recursive --delete  gnupg/hpc/ $(HPC_REPO_DIR)/gnupg/hpc/

	@echo -e "\033[34m‣ syncing configs\033[0m"
	@echo -e "\033[33m  - starship\033[0m"
	@rsync --checksum --copy-unsafe-links --perms --executability --times --recursive --delete  config/starship/ $(HPC_REPO_DIR)/config/starship
	@echo -e "\033[33m  - direnv\033[0m"
	@rsync --checksum --copy-unsafe-links --perms --executability --times --recursive --delete  config/direnv/ $(HPC_REPO_DIR)/config/direnv

	@echo -e "\033[34m‣ syncing meta\033[0m"
	@echo -e "\033[33m  - LICENSE\033[0m"
	@cp --preserve --force LICENSE.md $(HPC_REPO_DIR)/LICENSE.md
	@echo -e "\033[33m  - .gitignore\033[0m"
	@cp --preserve --force .gitignore $(HPC_REPO_DIR)/.gitignore
	@echo -e "\033[33m  - .editorconfig\033[0m"
	@echo -e "\033[33m  - signer\033[0m"
	@cp --preserve --force checksum.sh $(HPC_REPO_DIR)/checksum.sh
	@cp --preserve --force .editorconfig $(HPC_REPO_DIR)/.editorconfig
	@echo -e "\033[33m  - testing scripts\033[0m"
	@rsync --checksum --copy-unsafe-links --perms --executability --times --recursive --delete  tests/ $(HPC_REPO_DIR)/tests
	@echo -e "\033[33m  - ci-config\033[0m"
	@rsync --checksum --copy-unsafe-links --perms --executability --times --recursive --delete  --exclude='sync-hpc.yml'  .github/ $(HPC_REPO_DIR)/.github

	@echo -e "\033[33m  - copy reference\033[0m"
	@echo "tprasadtp/dotfiles@$(GITCOMMIT)" > $(HPC_REPO_DIR)/.upstream

.PHONY: install-tools
install-tools: ## Installs extra tools used by dotfiles (starship-rs and direnv)
	@echo -e "\033[1;92m➜ $@ \033[0m"
	./install.sh --tools

.PHONY: update-vim-plug
update-vim-plug: ## updates vim-plug(not plugins)
	@echo -e "\033[1;92m➜ $@ \033[0m"
	@mkdir -p vim/vim-plug vendor/source
	curl -sSfL -o vendor/source/vim-plug.json https://api.github.com/repos/junegunn/vim-plug/commits/master
	curl -sSfL -o vim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim


.PHONY: update-metadta
update-metadata: ## update medatata-hashes
	@echo -e "\033[1;92m➜ $@ \033[0m"
	vimplug_chash="$$(jq -r '.sha' vendor/source/vim-plug.json)";\
		__vimplug_cdate="$$(jq -r ".commit.committer.date" vendor/source/vim-plug.json)";\
		vimplug_cdate=`date --date "$${__vimplug_cdate}" "+%b-%d-%Y" `;\
		echo "{\"vimplug\": {\"commit\": \"$${vimplug_chash:0:7}\", \"sha1\": \"$${vimplug_chash}\", \"date\": \"$${vimplug_cdate}\"}}" | tee vendor/vendor.json


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
	install -g root -o root -m 640 system/sudo/sudo.lecture /etc/sudoers.d/sudo.lecture
	install -g root -o root -m 640 system/sudo/lecture /etc/sudoers.d/lecture
