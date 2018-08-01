VERSIONS = 5.0 5.1
VERSION_DOCS = $(addprefix doc-, $(VERSIONS))
VERSION_ARCHIVES = $(addsuffix .tar.gz, $(VERSION_DOCS))

GENERIC_DOCS = site site-dev site-local

SITES = $(GENERIC_DOCS) $(VERSION_DOCS)

.PHONY: prepare rudder-theme/build/ui-bundle.zip optipng doc-build build/sites/redirect-current.conf build/files $(SITES)
.DEFAULT_GOAL := local

all: $(GENERIC_DOCS) $(VERSION_ARCHIVES) build/sites/redirect-current.conf build/files test
online: site site-dev $(VERSION_ARCHIVES) build/sites/redirect-current.conf build/files test
local: site-local test

rudder-theme/build/ui-bundle.zip:
	cd rudder-theme && yarn install
	cd rudder-theme && gulp pack

# Ugly workaround until we can use custom generators in antora
doc-build:
	[ -d $@ ] || git clone https://github.com/Normation/rudder-doc.git $@
	cd $@ && git checkout branches/rudder/5.0 && git pull
	cd $@/src/reference && make
	cd $@ && git add -f src/reference && git commit --allow-empty -m "Build 5.0"
	cd $@ && git clean -fd
	cd $@ && git checkout master && git pull
	cd $@/src/reference && make
	cd $@ && git add -f src/reference && git commit --allow-empty -m "Build master"

# Prepare everything, even if not needed
prepare: doc-build
	cd src/reference && make

$(SITES): prepare rudder-theme/build/ui-bundle.zip
	antora --ui-bundle-url ./rudder-theme/build/ui-bundle.zip $@.yml

%.tar.gz: %
	mkdir -p build/archives
	cd build && tar -cvzf $@ $<
	mv build/$@ build/archives/
	rm -rf build/$<

# Generate apache conf for current redirection to latest release
build/sites/redirect-current.conf:
	# once 5.0 is relased, should be https://www.rudder-project.org/release-info/rudder/versions/latest
	echo 'RedirectMatch ^/reference/current/(.*)$$ /reference/5.0/$$1' > $@

# Download documentation files
build/files:
	mkdir -p build/files
	curl -o build/files/rudder-cheatsheet-advanced.pdf "https://raw.githubusercontent.com/Normation/rudder-tools/master/documents/cheatsheet-advanced/rudder-cheatsheet-advanced.pdf"

test:
	./tests/check_broken_links.sh

optipng:
	find src -name "*.png" -exec optipng {} \;

clean:
	cd src/reference && make clean
	rm -rf build rudder-theme/build
	rm -rf doc-build
