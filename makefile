BUILDDIR := build
CLIENTBUILD := $(BUILDDIR)/client
SERVERBUILD := $(BUILDDIR)/server
CLEANFILES :=  $(BUILDDIR)/ client/build build dist cellxgene.egg-info

PART ?= patch

# BUILDING PACKAGE

build : clean build-server
	@echo "done"

build-server : build-client
	mkdir -p $(SERVERBUILD)
	cp -r server/* $(SERVERBUILD)
	cp -r client/build/  $(CLIENTBUILD)
	mkdir -p $(SERVERBUILD)/app/web/static/img
	mkdir -p $(SERVERBUILD)/app/web/templates/
	cp $(CLIENTBUILD)/index.html $(SERVERBUILD)/app/web/templates/
	cp -r $(CLIENTBUILD)/static $(SERVERBUILD)/app/web/
	cp $(CLIENTBUILD)/favicon.png $(SERVERBUILD)/app/web/static/img
	cp $(CLIENTBUILD)/service-worker.js $(SERVERBUILD)/app/web/static/js/
	cp MANIFEST.in README.md setup.cfg setup.py $(BUILDDIR)

build-client :
	npm install --prefix client/ client
	npm run  --prefix client build

# If you are actively developing in the server folder use this, dirties the source tree
build-for-server-dev : clean-server build-client
	mkdir -p server/app/web/static/img
	mkdir -p server/app/web/static/js
	mkdir -p server/app/web/templates/
	cp client/build/index.html server/app/web/templates/
	cp -r client/build/static server/app/web/
	cp client/build/favicon.png server/app/web/static/img
	cp client/build/service-worker.js server/app/web/static/js/

clean : clean-lite clean-server
	rm -rf client/node_modules

# cleaning node_modules is the longest one, so we avoid that if possible
clean-lite :
	rm -rf $(CLEANFILES)

clean-server :
	rm -f server/app/web/templates/index.html
	rm -rf server/app/web/static

.PHONY : build build-server build-client build-for-server-dev clean clean-lite clean-server

# CREATING DISTRIBUTION RELEASE

pydist : build
	cd $(BUILDDIR); python setup.py sdist -d ../dist
	@echo "done"

.PHONY : pydist

# RELEASE HELPERS

# create new version to commit to master
release-stage-1 : dev-env bump clean-lite gen-package-lock
	@echo "Version bumped part:$(PART) and client built. Ready to commit and push"

# build dist and release to dev pypi
release-stage-2 : dev-env pydist twine
	@echo "Dist built and uploaded to test.pypi.org"
	@echo "Test the install:"
	@echo "    make install-release-test"
	@echo "Then upload to Pypi prod:"
	@echo "    make twine-prod"

release-stage-final: twine-prod
	@echo "Release uploaded to pypi.org"

# DANGER: releases directly to prod
# use this if you accidently burned a test release version number,
release-directly-to-prod : dev-env pydist twine-prod
	@echo "Dist built and uploaded to pypi.org"
	@echo "Test the install:"
	@echo "    make install-release"

dev-env :
	pip install -r server/requirements-dev.txt

gui-env : dev-env
	pip install -r server/requirements-gui.txt

# give PART=[major, minor, part] as param to make bump
bump :
	bumpversion --config-file .bumpversion.cfg $(PART)

twine :
	twine upload --repository-url https://test.pypi.org/legacy/ dist/*

twine-prod :
	twine upload dist/*

# quicker than re-building client
gen-package-lock :
	npm install --prefix client/ client

.PHONY : release-stage-1 release-stage-2 release-stage-final release-burned dev-env bump twine twine-prod gen-package-lock

# INSTALL

# setup.py sucks when you have your library in a separate folder, adding these in to help setup envs

# install from build directory
install : uninstall
	cd $(BUILDDIR); pip install -e .

# install from source tree for development
install-dev : uninstall
	pip install -e .

# install from test.pypi to test your release
install-release-test : uninstall
	pip install --no-cache-dir --index-url https://test.pypi.org/simple/ --extra-index-url https://pypi.org/simple cellxgene
	@echo "Installed cellxgene from test.pypi.org, now run and smoke test"

# install from pypi to test your release
install-release : uninstall
	pip install --no-cache-dir cellxgene
	@echo "Installed cellxgene from pypi.org"

# install from dist
install-dist : uninstall
	pip install dist/cellxgene*.tar.gz

uninstall :
	pip uninstall -y cellxgene || :

.PHONY : install install-dev install-release-test install-release uninstall

# GUI

build-assets :
	pyside2-rcc server/gui/cellxgene.qrc -o server/gui/cellxgene_rc.py

gui-spec-osx : clean-lite gui-env
	pip install -e .[gui]
	pyi-makespec -D -w --additional-hooks-dir server/gui/ -n cellxgene  --add-binary='/System/Library/Frameworks/Tk.framework/Tk':'tk' --add-binary='/System/Library/Frameworks/Tcl.framework/Tcl':'tcl'  --add-data server/app/web/templates/:server/app/web/templates/ --add-data server/app/web/static/:server/app/web/static/ --icon server/gui/images/cxg_icons.icns server/gui/main.py
	mv cellxgene.spec cellxgene-osx.spec

gui-spec-windows : clean-lite dev-env
	pip install -e .[gui]
	pyi-makespec -D -w --additional-hooks-dir server/gui/ -n cellxgene --add-data server/app/web/templates;server/app/web/templates --add-data server/app/web/static;server/app/web/static --icon server/gui/images/icon.ico server/gui/main.py
	mv cellxgene.spec cellxgene-windows.spec

gui-build-osx : clean-lite
	pyinstaller --clean cellxgene-osx.spec

gui-build-windows : clean-lite
	pyinstaller --clean cellxgene-windows.spec

.PHONY : build-assets gui-build-osx gui-build-windows gui-build-osx gui-build-windows

