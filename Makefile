SHELL := /bin/bash

.DEFAULT_GOAL := help

# Set install prefix if not set already
INSTALL_PREFIX ?= $(HOME)

.PHONY: test
test: shellcheck test-install-default  test-install-minimal ## Runs all the tests


.PHONY: shellcheck
shellcheck: ## Runs the shellcheck tests on the scripts.
	./tests/test-shell-scripts.sh

.PHONY: install
install: ## Installs default profile
	./install.sh -i -x -z

.PHONY: test-install-default
test-install-default: ## Test Installs default profile
	./install.sh -T --install

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

.PHONY: install-tools
install-tools: ## Installs extra tools used by dotfiles (starship-rs,fzf,fd and direnv)
	@echo -e "\033[1;92m➜ $@ \033[0m"
	./install.sh --tools

.PHONY: clean-downloads
clean-downloads: ## cleanup old downloads
	@rm -f vendor/{tools}/*.*

.PHONY: debug-vars
debug-vars: ## Debug Variables
	@echo "INSTALL_PREFIX: $(INSTALL_PREFIX)"
	@echo "XDG_CONFIG_HOME: $(XDG_CONFIG_HOME)"

.PHONY: install-system
install-system: ## Install system mods (Requires Root)
	@echo "Installing Sudo Lecture"
	install -g root -o root -m 640 system/sudo/sudo.lecture /etc/sudoers.d/sudo.lecture
	install -g root -o root -m 640 system/sudo/lecture /etc/sudoers.d/lecture
