CURRENT_SIGN_SETTING := $(shell git config commit.gpgSign)

.PHONY: clean-pyc clean-build docs

help:
	@echo "clean-build - remove build artifacts"
	@echo "clean-pyc - remove Python file artifacts"
	@echo "dist - package"
	@echo "lint - check style with flake8"
	@echo "lint-roll - automatically fix problems with isort, flake8, etc"
	@echo "release - package and upload a release (does not run notes target)"
	@echo "test - run tests quickly with the default Python"
	@echo "docs - generate docs and open in browser (linux-docs for version on linux)"
	@echo "notes - consume towncrier newsfragments/ and update release notes in docs/"
	@echo "release - package and upload a release (does not run notes target)"
	@echo "dist - package"

clean: clean-build clean-pyc

clean-build:
	rm -fr build/
	rm -fr dist/
	rm -fr *.egg-info

clean-pyc:
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -rf {} +

lint:
	tox run -e lint

lint-roll:
	isort --multi-line=VERTICAL_HANGING_INDENT --fgw=1 --ca trie tests
	black trie tests setup.py
	$(MAKE) lint

test:
	pytest --tb native tests

build-docs:
	sphinx-apidoc -o docs/ . setup.py "*conftest*"
	$(MAKE) -C docs clean
	$(MAKE) -C docs html
	$(MAKE) -C docs doctest

validate-docs:
	python ./newsfragments/validate_files.py
	towncrier build --draft --version preview

check-docs: build-docs validate-docs

docs: check-docs
	open docs/_build/html/index.html

linux-docs: check-docs
	xdg-open docs/_build/html/index.html

check-bump:
ifndef bump
	$(error bump must be set, typically: major, minor, patch, or devnum)
endif

release: check-bump clean
	# require that you be on a branch that's linked to upstream/master
	git status -s -b | head -1 | grep "\.\.upstream/master"
	# verify that docs build correctly
	./newsfragments/validate_files.py is-empty
	make build-docs
	CURRENT_SIGN_SETTING=$(git config commit.gpgSign)
	git config commit.gpgSign true
	bumpversion $(bump)
	git push upstream && git push upstream --tags
	python -m build
	twine upload dist/*
	git config commit.gpgSign "$(CURRENT_SIGN_SETTING)"

dist: clean
	python -m build
	ls -l dist
