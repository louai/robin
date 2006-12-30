ver = 1.0
minor = 2

###
# Installation
###

prefix = /usr/local
exec_prefix = /usr/local
site_packages = /usr/local/lib/python2.4/site-packages
python = python
jython = jython
-include config.mak

pydir = $(site_packages)/robin
libdir = $(exec_prefix)/lib
scriptdir = $(prefix)/bin
jardir = $(libdir)/griffin
sopre := ${shell $(python) -c "import griffin; print griffin.sopre"}
soext := ${shell $(python) -c "import griffin; print griffin.soext"}
cpu = ${shell uname -m}
target = ${shell $(python) -c "import griffin; print griffin.arch"}

ifeq ($(multi-platform),1)
plat := ${shell $(python) -c "import griffin; print griffin.platspec"}
py := ${shell $(python) -c "import griffin; print griffin.pyspec"}
endif

install = install -D
cp-r = cp -r
sed = sed
echo = echo

INSTALLABLE_FILES = \
	$(libdir)/$(vpath)$(sopre)robin$(plat)-$(ver)$(py)$(soext) \
	$(libdir)/$(vpath)$(sopre)robin_pyfe$(plat)-$(ver)$(py)$(soext) \
	$(libdir)/$(vpath)$(sopre)robin_stl$(plat)-$(ver)$(py)$(soext) \
	$(scriptdir)/griffin \
	$(jardir)/Griffin.jar \
	$(pydir).pth \
	$(pydir)/robin.py $(pydir)/griffin.py \
	$(pydir)/stl.py $(pydir)/robinhelp.py $(pydir)/document.py \
	$(pydir)/pickle_weakref.py \
	$(pydir)/html/__init__.py $(pydir)/html/textformat.py \
	$(pydir)/robinlib/__init__.py $(pydir)/robinlib/platform.py \
	$(pydir)/robinlib/config.py \
	$(jardir)/stl.st.xml $(jardir)/stl.tag 

INSTALLABLE_DIRS = $(jardir)/dox-xml $(jardir)/premises

default all:
	scons

install: $(INSTALLABLE_FILES) $(INSTALLABLE_DIRS) ;

$(pydir)/robin.py: robin.py
	$(install) $< $@
	$(sed) -i -e 's@libdir =.*@libdir = "$(libdir)"@' $@

$(pydir)/griffin.py: griffin.py
	$(install) $< $@

$(pydir)/%.py: src/robin/modules/%.py
	$(install) $< $@

$(pydir).pth:
	$(echo) robin > $@

$(libdir)/$(vpath)%$(soext): %$(soext)
	$(install) $< $@

$(scriptdir)/griffin: griffin
	$(install) $< $@
	$(sed) -i -e 's@here =.*@here = os.path.expanduser("$(jardir)")@' $@
	# using 'wildcard' to expand ~ if present
	$(sed) -i -e 's@#!/usr/bin/env python@#!$(wildcard $(python))@' $@

$(jardir)/Griffin.jar: Griffin.jar
	$(install) $< $@

$(jardir)/premises: $(jardir)/Griffin.jar premises
	$(cp-r) premises $@

$(jardir)/stl.st.xml: src/griffin/modules/stl/stl.st.xml
	$(install) $< $@

$(jardir)/stl.tag: build/stl.tag
	$(install) $< $@

$(jardir)/dox-xml: build/dox-xml
	$(cp-r) $< $(jardir)

uninstall:
	-rm -f $(INSTALLABLE_FILES)
	-rm -fr $(pydir)
	-rm -fr $(jardir)


###
# Testing
###

extreme_python = src/robin/extreme/python
SELF = PATH=$(PWD):$(PWD)/src/robin/modules:$$PATH \
       LD_LIBRARY_PATH=$(PWD) \
       PYTHONPATH=$(PWD):$(PWD)/src/robin/modules
. = .

language-test@%:
	$($*)/griffin $G -I --in $(extreme_python)/language.h            \
	        --out $(extreme_python)/liblanguage_robin.cc             \
	        El DataMembers PrimitiveTypedef EnumeratedValues Aliases \
	        DerivedFromAlias Inners Constructors AssignmentOperator  \
	        Conversions Exceptions Interface Abstract NonAbstract    \
	        Primitives Pointers UsingStrings UsingStringConversions  \
	        UsingVectors UsingPairs UsingComplex
	$(CXX) -shared $(extreme_python)/liblanguage_robin.cc            \
	        -o $(extreme_python)/liblanguage.so

protocols-test@%:
	$($*)/griffin --in $(extreme_python)/protocols.h                 \
	        --out $(extreme_python)/libprotocols_robin.cc            \
	        Times
	$(CXX) -shared $(extreme_python)/libprotocols_robin.cc           \
	        $(extreme_python)/protocols.cc                           \
	        -o $(extreme_python)/libprotocols.so

inheritance-test@%:
	$($*)/griffin --in $(extreme_python)/inheritance.h               \
	        --out $(extreme_python)/libinheritance_robin.cc          \
	        --interceptors Functor mapper
	$(CXX) -shared $(extreme_python)/libinheritance_robin.cc         \
		-o $(extreme_python)/libinheritance.so

hints-test@%:
	$($*)/griffin --in $(extreme_python)/hinted.h -I                 \
	        --out $(extreme_python)/libhints_robin.cc                \
	        --hints=$(extreme_python)/hint.py Clue
	$(CXX) -shared $(extreme_python)/libhints_robin.cc         \
		-o $(extreme_python)/libhints.so

autocollect-test@%:
	$($*)/griffin --in $(extreme_python)/autocollect.h               \
	        --out $(extreme_python)/libautocollect_robin.cc
	$(CXX) -shared $(extreme_python)/libautocollect_robin.cc   \
		-o $(extreme_python)/libautocollect.so

TESTS = language-test protocols-test inheritance-test hints-test autocollect-test
TEST_SUITES = LanguageTest ProtocolsTest InheritanceTest HintsTest
TESTING_PYTHON = cd $(extreme_python) && $(SELF) $(python)
TESTING_PYTHON_GDB = cd $(extreme_python) && $(SELF) gdb --args $(python)
TESTING_PYTHON_VG = cd $(extreme_python) && $(SELF) valgrind --tool=memcheck $(python)

test: ${addsuffix @., $(TESTS)}
	( $(TESTING_PYTHON) test_cases.py $(TEST_SUITES) )

justtest:
	( $(TESTING_PYTHON) test_cases.py $(TEST_SUITES) )

systest: ${addsuffix @scriptdir, $(TESTS)}
	( cd $(extreme_python) && \
	        $(python) test_cases.py $(TEST_SUITES) )

jytest:
	$(jython) tests/tests.py $(ARGS)

# - development tools
interactive:
	$(TESTING_PYTHON)

debug:
	( $(TESTING_PYTHON_GDB) test_cases.py $(TEST_SUITES) )

memcheck:
	( $(TESTING_PYTHON_VG) test_cases.py $(TEST_SUITES) )


###
# Distribution
###
manifest:
	$(MAKE) -n install prefix=/demo exec_prefix=/demo site_packages=/demo \
	  install=install cp-r=install \
	   | grep '^install' | awk '{ print $$2; }' \
	   | xargs --replace find {} -type f -o -name .svn -prune -false \
	   > manifest
	echo Makefile >> manifest
	echo configure >> manifest

.PHONY: distrib

distrib: manifest
	@rm -rf distrib/robin
	mkdir -p distrib/robin
	tar cf - --files-from manifest | ( cd distrib/robin && tar xf - )
	tar zcf distrib/robin-$(ver).$(minor).$(cpu).$(target).tar.gz \
		-C distrib robin

srcdistrib:
	-rm -rf distrib/robin
	mkdir -p distrib
	svn export . distrib/robin
	rm -rf distrib/robin/premises
	tar zcf distrib/robin-$(ver).$(minor).src.tar.gz -C distrib robin
