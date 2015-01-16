PACKAGE = s6-dns
ORG = amylum
BUILD_DIR = /tmp/$(PACKAGE)-build
RELEASE_DIR = /tmp/$(PACKAGE)-release
RELEASE_FILE = /tmp/$(PACKAGE).tar.gz

PACKAGE_VERSION = $$(awk -F= '/^version/ {print $$2}' upstream/package/info)
PATCH_VERSION = $$(cat version)
VERSION = $(PACKAGE_VERSION)-$(PATCH_VERSION)
CONF_FLAGS = --enable-allstatic --enable-static --enable-static-libc
PATH_FLAGS = --prefix=$(RELEASE_DIR) --exec-prefix=$(RELEASE_DIR)/usr --includedir=$(RELEASE_DIR)/usr/include --libdir=$(RELEASE_DIR)/usr/lib

SKALIBS_VERSION = 2.2.0.0-14
SKALIBS_URL = https://github.com/amylum/skalibs/releases/download/$(SKALIBS_VERSION)/skalibs.tar.gz
SKALIBS_TAR = skalibs.tar.gz
SKALIBS_DIR = /tmp/skalibs
SKALIBS_PATH = --with-sysdeps=$(SKALIBS_DIR)/usr/lib/skalibs/sysdeps --with-lib=$(SKALIBS_DIR)/usr/lib/skalibs --with-include=$(SKALIBS_DIR)/usr/include --with-dynlib=$(SKALIBS_DIR)/usr/lib

.PHONY : default manual container deps version build push local

default: upstream/Makefile container

upstream/Makefile:
	git submodule update --init

manual:
	./meta/launch /bin/bash || true

container:
	./meta/launch

deps:
	rm -rf $(SKALIBS_DIR) $(SKALIBS_TAR)
	mkdir $(SKALIBS_DIR)
	curl -sLo $(SKALIBS_TAR) $(SKALIBS_URL)
	tar -x -C $(SKALIBS_DIR) -f $(SKALIBS_TAR)
	cp -R /usr/include/{linux,asm,asm-generic} $(SKALIBS_DIR)/usr/include/

build: deps
	rm -rf $(BUILD_DIR)
	cp -R upstream $(BUILD_DIR)
	cd $(BUILD_DIR) && CC="musl-gcc" ./configure $(CONF_FLAGS) $(PATH_FLAGS) $(SKALIBS_PATH)
	make -C $(BUILD_DIR)
	make -C $(BUILD_DIR) install
	cd $(RELEASE_DIR) && tar -czvf $(RELEASE_FILE) *

version:
	@echo $$(($(PATCH_VERSION) + 1)) > version

push: version
	git commit -am "$(VERSION)"
	ssh -oStrictHostKeyChecking=no git@github.com &>/dev/null || true
	git tag -f "$(VERSION)"
	git push --tags origin master
	targit -a .github -c -f $(ORG)/$(PACKAGE) $(VERSION) $(RELEASE_FILE)

local: build push

