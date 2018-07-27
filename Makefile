.PHONY: prepare build/site/ rudder-theme/build/ui-bundle.zip optipng build-5.0

html: build/site/

rudder-theme/build/ui-bundle.zip:
	cd rudder-theme && yarn install
	cd rudder-theme && gulp pack

# Ugly workaround until we can use custom generators in antora
doc-5.0:
	git clone https://github.com/Normation/rudder-doc.git doc-5.0
	cd doc-5.0 && git checkout branches/rudder/5.0 && git checkout -b 5.0

build-5.0: doc-5.0
	cd doc-5.0 && git pull origin branches/rudder/5.0
	cd doc-5.0/src/reference && make

prepare: build-5.0
	cd src/reference && make

build/site/: prepare rudder-theme/build/ui-bundle.zip
	antora --ui-bundle-url ./rudder-theme/build/ui-bundle.zip site.yml

test: build/site/
	./tests/check_broken_links.sh

optipng:
	find src -name "*.png" -exec optipng {} \;

clean:
	cd src/reference && make clean
	rm -rf build rudder-theme/build
	rm -rf doc-5.0
