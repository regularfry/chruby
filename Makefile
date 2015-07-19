NAME=chruby
VERSION=0.3.9
AUTHOR=postmodern
URL=https://github.com/$(AUTHOR)/$(NAME)

DIRS=etc lib bin sbin share
INSTALL_DIRS=`find $(DIRS) -type d 2>/dev/null`
INSTALL_FILES=`find $(DIRS) -type f 2>/dev/null`
DOC_FILES=*.md *.txt

PKG_DIR=pkg
PKG_NAME=$(NAME)-$(VERSION)
PKG=$(PKG_DIR)/$(PKG_NAME).tar.gz
SIG=$(PKG).asc

DESTDIR?=/
PREFIX?=/usr/local
INSTALL_PATH=$(DESTDIR)/$(PREFIX)
DOC_DIR?=$(INSTALL_PATH)/share/doc/$(NAME)

pkg:
	mkdir $(PKG_DIR)

share/man/man1/chruby.1: doc/man/chruby.1.md
	kramdown-man <doc/man/chruby.1.md >share/man/man1/chruby.1

share/man/man1/chruby-exec.1: doc/man/chruby-exec.1.md
	kramdown-man <doc/man/chruby-exec.1.md >share/man/man1/chruby-exec.1

man: share/man/man1/chruby.1
	git commit -m "Updated the man pages" doc/man/chruby.1.md share/man/man1/chruby.1

man: share/man/man1/chruby-exec.1
	git commit -m "Updated the man pages" doc/man/chruby-exec.1.md share/man/man1/chruby-exec.1

download: pkg
	wget -O $(PKG) $(URL)/archive/v$(VERSION).tar.gz

build: pkg
	git archive --output=$(PKG) --prefix=$(PKG_NAME)/ HEAD

sign: $(PKG)
	gpg --sign --detach-sign --armor $(PKG)
	git add $(PKG).asc
	git commit $(PKG).asc -m "Added PGP signature for v$(VERSION)"
	git push origin master

verify: $(PKG) $(SIG)
	gpg --verify $(SIG) $(PKG)

clean:
	rm -rf test/opt/rubies
	rm -f $(PKG) $(SIG)

all: $(PKG) $(SIG)

check:
	shellcheck share/$(NAME)/*.sh

test/opt/rubies:
	./test/setup

test: test/opt/rubies
	SHELL=`command -v bash` ./test/runner
	SHELL=`command -v zsh`  ./test/runner

tag:
	git push origin master
	git tag -s -m "Releasing $(VERSION)" v$(VERSION)
	git push origin master --tags

release: tag download sign

rpm:
	rpmdev-setuptree
	spectool -g -R rpm/chruby.spec
	rpmbuild -ba rpm/chruby.spec

install:
	for dir in $(INSTALL_DIRS); do mkdir -p $(DESTDIR)$(PREFIX)/$$dir; done
	for file in $(INSTALL_FILES); do cp $$file $(DESTDIR)$(PREFIX)/$$file; done
	mkdir -p $(DESTDIR)$(DOC_DIR)
	cp -r $(DOC_FILES) $(DESTDIR)$(DOC_DIR)/

uninstall:
	for file in $(INSTALL_FILES); do rm -f $(DESTDIR)$(PREFIX)/$$file; done
	rm -rf $(DESTDIR)$(DOC_DIR)

.PHONY: build download sign verify clean check test tag release rpm install uninstall all
