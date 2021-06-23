SHELL := /bin/bash
.DEFAULT_GOAL := help
export REPO_ROOT := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))


.PHONY: shellcheck
shellcheck: ## Run shellcheck
	@./hack/shellcheck.sh $(shell find . -type f \
		-not -iwholename '*.git*' \
		-not -iwholename 'vendor*' \
		-not -iwholename '**/*fetch*' \
		-not -iwholename '**/fish/**' \
		-not -iwholename '**/config/fish*' \
		-not -iwholename '**/ml-formatter' \
		-not -iwholename '**/*.bats' \
		-executable | sort -u)

install: ## Installs default profile
	./install.sh --install

.PHONY: test-install
test-install: ## Test Installs default profile
	./install.sh --install --debug --verbose

.PHONY: test-install-minimal
test-install-minimal: ## Test Install minimal profile
	./install.sh --minimal --debug --verbose

.PHONY: verify
verify: ## Verifies checksums
	./sign.sh --verify

.PHONY: sign
sign: ## Sign
	./sign.sh --sign --verify

.PHONY: help
help: ## This help dialog.
	@IFS=$$'\n' ; \
    help_lines=(`fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##/:/'`); \
    printf "%-30s %s\n" "--------" "------------" ; \
	printf "%-30s %s\n" " Target " "   Help     " ; \
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

.PHONY: test-libs
test-libs: ## Run go test on all packages
	go test $(REPO_ROOT)/... -count=1 -v

.PHONY: install-tools
install-tools: ## Installs extra tools used by dotfiles (starship-rs,fzf,fd and direnv)
	@echo -e "\033[1;92m➜ $@ \033[0m"
	./install.sh --tools

.PHONY: clean-downloads
clean-downloads: ## cleanup old downloads
	@rm -f vendor/{tools}/*.*

.PHONY: show-broken
show-broken: ## Show broken symlinks
	@find ~/.config/ -xtype l

.PHONY: debug-vars
debug-vars: ## Debug Variables
	@echo "INSTALL_PREFIX: $(INSTALL_PREFIX)"
	@echo "XDG_CONFIG_HOME: $(XDG_CONFIG_HOME)"

.PHONY: install-system
install-system: ## Install system mods (Requires Root)
	@echo "Installing Sudo Lecture"
	install -g root -o root -m 640 system/sudo/sudo.lecture /etc/sudoers.d/sudo.lecture
	install -g root -o root -m 640 system/sudo/lecture /etc/sudoers.d/lecture
