PACKAGE = s6-networking
ORG = amylum
BUILD_DIR = /tmp/$(PACKAGE)-build
RELEASE_DIR = /tmp/$(PACKAGE)-release
RELEASE_FILE = /tmp/$(PACKAGE).tar.gz

PACKAGE_VERSION = $$(awk -F= '/^version/ {print $$2}' upstream/package/info)
PATCH_VERSION = $$(cat version)
VERSION = $(PACKAGE_VERSION)-$(PATCH_VERSION)
CONF_FLAGS = --enable-allstatic --enable-static --enable-static-libc
PATH_FLAGS = --prefix=$(RELEASE_DIR) --exec-prefix=$(RELEASE_DIR)/usr --includedir=$(RELEASE_DIR)/usr/include --libdir=$(RELEASE_DIR)/usr/lib

SKALIBS_VERSION = 2.3.7.0-33
SKALIBS_URL = https://github.com/amylum/skalibs/releases/download/$(SKALIBS_VERSION)/skalibs.tar.gz
SKALIBS_TAR = skalibs.tar.gz
SKALIBS_DIR = /tmp/skalibs
SKALIBS_PATH = --with-sysdeps=$(SKALIBS_DIR)/usr/lib/skalibs/sysdeps --with-lib=$(SKALIBS_DIR)/usr/lib/skalibs --with-include=$(SKALIBS_DIR)/usr/include --with-dynlib=$(SKALIBS_DIR)/usr/lib

EXECLINE_VERSION = 2.1.4.0-24
EXECLINE_URL = https://github.com/amylum/execline/releases/download/$(EXECLINE_VERSION)/execline.tar.gz
EXECLINE_TAR = execline.tar.gz
EXECLINE_DIR = /tmp/execline
EXECLINE_PATH = --with-lib=$(EXECLINE_DIR)/usr/lib/execline --with-include=$(EXECLINE_DIR)/usr/include --with-lib=$(EXECLINE_DIR)/usr/lib

S6_VERSION = 2.2.0.0-32
S6_URL = https://github.com/amylum/s6/releases/download/$(S6_VERSION)/s6.tar.gz
S6_TAR = s6.tar.gz
S6_DIR = /tmp/s6
S6_PATH = --with-lib=$(S6_DIR)/usr/lib/s6 --with-include=$(S6_DIR)/usr/include --with-lib=$(S6_DIR)/usr/lib

S6-DNS_VERSION = 2.0.0.4-17
S6-DNS_URL = https://github.com/amylum/s6-dns/releases/download/$(S6-DNS_VERSION)/s6-dns.tar.gz
S6-DNS_TAR = s6-dns.tar.gz
S6-DNS_DIR = /tmp/s6-dns
S6-DNS_PATH = --with-lib=$(S6-DNS_DIR)/usr/lib/s6-dns --with-include=$(S6-DNS_DIR)/usr/include --with-lib=$(S6-DNS_DIR)/usr/lib

.PHONY : default submodule manual container deps version build push local

default: submodule container

submodule:
	git submodule update --init

manual: submodule
	./meta/launch /bin/bash || true

container:
	./meta/launch

deps:
	rm -rf $(SKALIBS_DIR) $(SKALIBS_TAR) $(EXECLINE_DIR) $(EXECLINE_TAR) $(S6_DIR) $(S6_TAR) $(S6-DNS_DIR) $(S6-DNS_TAR)
	mkdir $(SKALIBS_DIR) $(EXECLINE_DIR) $(S6_DIR) $(S6-DNS_DIR)
	curl -sLo $(SKALIBS_TAR) $(SKALIBS_URL)
	tar -x -C $(SKALIBS_DIR) -f $(SKALIBS_TAR)
	curl -sLo $(EXECLINE_TAR) $(EXECLINE_URL)
	tar -x -C $(EXECLINE_DIR) -f $(EXECLINE_TAR)
	curl -sLo $(S6_TAR) $(S6_URL)
	tar -x -C $(S6_DIR) -f $(S6_TAR)
	curl -sLo $(S6-DNS_TAR) $(S6-DNS_URL)
	tar -x -C $(S6-DNS_DIR) -f $(S6-DNS_TAR)
	cp -R /usr/include/{linux,asm,asm-generic} $(SKALIBS_DIR)/usr/include/

build: submodule deps
	rm -rf $(BUILD_DIR)
	cp -R upstream $(BUILD_DIR)
	sed -i 's/0700/0755/' $(BUILD_DIR)/package/modes
	cd $(BUILD_DIR) && CC="musl-gcc" ./configure $(CONF_FLAGS) $(PATH_FLAGS) $(SKALIBS_PATH) $(EXECLINE_PATH) $(S6_PATH) $(S6-DNS_PATH)
	make -C $(BUILD_DIR)
	make -C $(BUILD_DIR) install
	mkdir -p $(RELEASE_DIR)/usr/share/licenses/$(PACKAGE)
	cp upstream/COPYING $(RELEASE_DIR)/usr/share/licenses/$(PACKAGE)/LICENSE
	cd $(RELEASE_DIR) && tar -czvf $(RELEASE_FILE) *

version:
	@echo $$(($(PATCH_VERSION) + 1)) > version

push: version
	git commit -am "$(VERSION)"
	ssh -oStrictHostKeyChecking=no git@github.com &>/dev/null || true
	git tag -f "$(VERSION)"
	git push --tags origin master
	@sleep 3
	targit -a .github -c -f $(ORG)/$(PACKAGE) $(VERSION) $(RELEASE_FILE)

local: build push

