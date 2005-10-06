
prefix = /usr/local
exec_prefix = /usr/local
site_packages = /usr/local/lib/python2.4/site-packages
python = python

pydir = $(site_packages)/robin
libdir = $(exec_prefix)/lib
scriptdir = $(prefix)/bin
jardir = $(libdir)/griffin
soext = .so

INSTALLABLE_FILES = \
	$(libdir)/librobin$(soext) \
	$(libdir)/librobin_pyfe$(soext) \
	$(libdir)/librobin_stl$(soext) \
	$(scriptdir)/griffin \
	$(jardir)/Griffin.jar \
	$(pydir).pth \
	$(pydir)/robin.py $(pydir)/griffin.py \
	$(pydir)/stl.py $(pydir)/robinhelp.py $(pydir)/document.py \
	$(pydir)/pickle_weakref.py \
	$(pydir)/html/__init__.py $(pydir)/html/textformat.py \
	$(jardir)/stl.st.xml $(jardir)/stl.tag 

INSTALLABLE_DIRS = $(jardir)/dox-xml $(jardir)/premises

default all:
	scons

install: $(INSTALLABLE_FILES) $(INSTALLABLE_DIRS) ;

$(pydir)/robin.py: robin.py
	install -D $< $@
	sed -i -e 's@libdir =.*@libdir = "$(libdir)"@' $@

$(pydir)/griffin.py: griffin.py
	install -D $< $@

$(pydir)/%.py: src/robin/modules/%.py
	install -D $< $@

$(pydir).pth:
	echo robin > $@

$(libdir)/%$(soext): %$(soext)
	install -D $< $@

$(scriptdir)/griffin: griffin
	install -D $< $@
	sed -i -e 's@here =.*@here = "$(jardir)"@' $@

$(jardir)/Griffin.jar: Griffin.jar
	install -D $< $@

$(jardir)/premises: $(jardir)/Griffin.jar premises
	cp -r premises $@

$(jardir)/stl.st.xml: src/griffin/modules/stl/stl.st.xml
	install -D $< $@

$(jardir)/stl.tag: build/stl.tag
	install -D $< $@

$(jardir)/dox-xml: build/dox-xml
	cp -r $< $(jardir)

uninstall:
	-rm -f $(INSTALLABLE_FILES)
	-rm -r $(pydir)
	-rm -r $(jardir)

extreme_python = src/robin/extreme/python

language-test:
	$(scriptdir)/griffin -in $(extreme_python)/language.h            \
	        -out $(extreme_python)/liblanguage_robin.cc              \
	        El DataMembers PrimitiveTypedef EnumeratedValues Aliases \
	        DerivedFromAlias Inners Constructors AssignmentOperator  \
	        Conversions Exceptions Interface Abstract NonAbstract    \
	        Primitives UsingStrings UsingStringConversions           \
	        UsingVectors UsingPairs
	g++ -shared $(extreme_python)/liblanguage_robin.cc               \
	        -o $(extreme_python)/liblanguage.so

protocols-test:
	$(scriptdir)/griffin -in $(extreme_python)/protocols.h           \
	        -out $(extreme_python)/libprotocols_robin.cc             \
	        Times
	g++ -shared $(extreme_python)/libprotocols_robin.cc              \
	        $(extreme_python)/protocols.cc                           \
	        -o $(extreme_python)/libprotocols.so

test: language-test protocols-test
	( cd $(extreme_python) && \
	        $(python) test_cases.py LanguageTest ProtocolsTest )