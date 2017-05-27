.DEFAULT_GOAL := help

NODES := $(shell docker-compose config --services | sed -e 's/_/-/g' | xargs)

up: ; docker-compose up -d

build-up: ; docker-compose up --build -d

down: ; docker-compose down

define interactive_shell_template
sh-$(1): up ; docker exec -ti $(1) bash
endef

$(foreach node,$(NODES),$(eval $(call interactive_shell_template,$(node))))

# iTerm2 && MacOSX only
iterms: ; osascript utils/iterm2-interactive.scpt $(shell pwd)

help:
	@echo
	@echo "Available targets:"
	@echo
	@echo " * up            start the testbed"
	@echo " * build-up      build images before starting the testbed"
	@echo " * down          stop the testbed"
	@echo " * sh-<node>     start interactive shell on <node>"
	@echo "                 where <node> is one of: $(NODES)"
	@echo
