PACKAGE=rima
VERSION=0.02

LUA= $(shell echo `which lua`)
LUA_BINDIR= $(shell echo `dirname $(LUA)`)
LUA_PREFIX= $(shell echo `dirname $(LUA_BINDIR)`)
LUA_SHAREDIR=$(LUA_PREFIX)/share/lua/5.1
LUA_LIBDIR=$(LUA_PREFIX)/lib/lua/5.1
LUA_INCDIR=$(LUA_PREFIX)/include

COIN_PREFIX=/usr/local
COIN_LIBDIR=$(COIN_PREFIX)/lib
COIN_INCDIR=$(COIN_PREFIX)/include/coin

LPSOLVE_PREFIX=/usr/local
LPSOLVE_LIBDIR=$(LPSOLVE_PREFIX)/lib
LPSOLVE_INCDIR=$(LPSOLVE_PREFIX)/include/lpsolve

CPP=g++
#-DNOMINMAX is needed for some compilers on windows.  I'm no sure which, so I guess I'll just blanket-add it for now.  Can't hurt, right?
CFLAGS=-O3 -DNOMINMAX -arch i686 -arch x86_64
SO_SUFFIX=so
SHARED=-bundle -bundle_loader $(LUA)

all: rima_clp_core.$(SO_SUFFIX) rima_cbc_core.$(SO_SUFFIX) rima_lpsolve_core.$(SO_SUFFIX)

rima_clp_core.$(SO_SUFFIX): c/rima_clp_core.cpp 
	$(CPP) $(CFLAGS) $(SHARED) $^ -o $@ -L$(COIN_LIBDIR)  -lclp -lcoinutils -I$(COIN_INCDIR)/clp -I$(COIN_INCDIR)/utils -I$(COIN_INCDIR)/headers

rima_cbc_core.$(SO_SUFFIX): c/rima_cbc_core.cpp
	$(CPP) $(CFLAGS) $(SHARED) $^ -o $@ -L$(COIN_LIBDIR) -lcbc -losiclp -I$(COIN_INCDIR)/cbc -I$(COIN_INCDIR)/osi -I$(COIN_INCDIR)/clp -I$(COIN_INCDIR)/utils -I$(COIN_INCDIR)/headers

rima_lpsolve_core.$(SO_SUFFIX): c/rima_lpsolve_core.cpp
	$(CPP) $(CFLAGS) $(SHARED) $^ -o $@ -L$(LPSOLVE_LIBDIR) -llpsolve55 -I$(LPSOLVE_INCDIR)

test: all
	cp rima_clp_core.so lua/
	cp rima_cbc_core.so lua/
	cp rima_lpsolve_core.so lua/
	cd lua; $(LUA) rima-test.lua; $(LUA) rima-test-solvers.lua
	cd lua; for f in `find ../docs -name "*.txt"`; do $(LUA) test/doctest.lua -i $$f > /dev/null; done

install: rima_lpsolve_core.so
	mkdir -p $(LUA_SHAREDIR)
	mkdir -p $(LUA_LIBDIR)
	cp lua/rima.lua $(LUA_SHAREDIR)
	cp -r lua/rima $(LUA_SHAREDIR)
	cp rima_clp_core.so $(LUA_LIBDIR)
	cp rima_cbc_core.so $(LUA_LIBDIR)
	cp rima_lpsolve_core.so $(LUA_LIBDIR)

doc:
	cd lua; for f in `find ../docs -name "*.txt"`; do n=`basename $$f .txt`; $(LUA) test/doctest.lua -sh -i $$f | markdown.lua -e ../docs/header.html -f ../docs/footer.html > ../htmldocs/$$n.html; done

dist: doc
	rm -f dist.files
	rm -rf $(PACKAGE)-$(VERSION)
	rm -f $(PACKAGE)-$(VERSION).tar.gz
	find * | grep -v "\.svn" | grep -v "\.DS_Store" | grep -v "build" | grep -v ".so" > dist.files
	mkdir -p $(PACKAGE)-$(VERSION)
	cpio -p $(PACKAGE)-$(VERSION) < dist.files
	tar czvf $(PACKAGE)-$(VERSION).tar.gz $(PACKAGE)-$(VERSION)
	rm -f dist.files
	rm -rf $(PACKAGE)-$(VERSION)
