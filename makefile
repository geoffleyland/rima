PACKAGE=rima
VERSION=0.05

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

CPP=/usr/bin/g++
#-DNOMINMAX is needed for some compilers on windows.  I'm not sure which, so I guess I'll just blanket-add it for now.  Can't hurt, right?
CFLAGS=-O3 -DNOMINMAX -fPIC
SO_SUFFIX=so

# Guess a platform
UNAME=$(shell uname -s)
ifneq (,$(findstring Darwin,$(UNAME)))
  # OS X
#  CFLAGS:=$(CFLAGS) -arch i686 -arch x86_64 # coin's really not set up for fat binaries
  SHARED=-bundle -undefined dynamic_lookup
  LIBS=
else
  # Linux
  SHARED=-shared -llua
  LIBS=-lcstring
endif


all: clp cbc lpsolve

clp: lua/rima_clp_core.$(SO_SUFFIX)

cbc: lua/rima_cbc_core.$(SO_SUFFIX)

lpsolve: lua/rima_lpsolve_core.$(SO_SUFFIX)

ipopt: lua/rima_ipopt_core.$(SO_SUFFIX)

lua/rima_clp_core.$(SO_SUFFIX): c/rima_clp_core.cpp c/rima_solver_tools.cpp
	$(CPP) $(CFLAGS) $(SHARED) $^ -o $@ -L$(COIN_LIBDIR)  -lclp -lcoinutils -lcoinmumps -lcoinmetis -lbz2 -lz -framework vecLib $(LIBS) -I$(LUA_INCDIR) -I$(COIN_INCDIR)

lua/rima_cbc_core.$(SO_SUFFIX): c/rima_cbc_core.cpp c/rima_solver_tools.cpp
	$(CPP) $(CFLAGS) $(SHARED) $^ -o $@ -L$(COIN_LIBDIR) -lcbc -losi -losiclp -lclp -lcgl -lcoinutils -lcoinmumps -lcoinmetis -framework vecLib $(LIBS) -I$(LUA_INCDIR) -I$(COIN_INCDIR)

lua/rima_lpsolve_core.$(SO_SUFFIX): c/rima_lpsolve_core.cpp c/rima_solver_tools.cpp
	$(CPP) $(CFLAGS) $(SHARED) $^ -o $@ -L$(LPSOLVE_LIBDIR) -llpsolve55 $(LIBS) -I$(LUA_INCDIR) -I$(LPSOLVE_INCDIR)

lua/rima_ipopt_core.$(SO_SUFFIX): c/rima_ipopt_core.cpp
	$(CPP) $(CFLAGS) $(SHARED) $^ -o $@ -L$(COIN_LIBDIR) -lipopt -lcoinmumps -lcoinmetis -lgfortran -framework vecLib $(LIBS) -I$(LUA_INCDIR) -I$(COIN_INCDIR)

test: all lua/rima.lua
	cd lua; $(LUA) rima-test.lua; $(LUA) rima-test-solvers.lua
	cd lua; for f in `find ../docs -name "*.txt"`; do $(LUA) test/doctest.lua -i $$f > /dev/null; done

install: lua/rima.lua
	mkdir -p $(LUA_SHAREDIR)
	mkdir -p $(LUA_LIBDIR)
	cp lua/rima.lua $(LUA_SHAREDIR)
	cp -r lua/rima $(LUA_SHAREDIR)
	-cp lua/rima_*_core.so $(LUA_LIBDIR)

uninstall: 
	rm -f $(LUA_SHAREDIR)/rima.lua
	rm -rf $(LUA_SHAREDIR)/rima
	-rm $(LUA_LIBDIR)/rima_*_core.so

doc: lua/rima.lua
	cd lua; for f in `find ../docs -name "*.txt"`; do n=`basename $$f .txt`; $(LUA) test/doctest.lua -sh -i $$f | markdown.lua -e ../docs/header.html -f ../docs/footer.html > ../htmldocs/$$n.html; done

dist: doc
	rm -f dist.files
	rm -rf $(PACKAGE)-$(VERSION)
	rm -f $(PACKAGE)-$(VERSION).tar.gz
	find * | grep -v "\.svn" | grep -v "^\.DS_Store$$" | grep -v "^build$$" | grep -v "\.so$$" | grep -v "\.o$$" | grep -v "\.git" | grep -v "\.rockspec" | grep -v "update-copyright.sh" > dist.files
	mkdir -p $(PACKAGE)-$(VERSION)
	cpio -p $(PACKAGE)-$(VERSION) < dist.files
	tar czvf $(PACKAGE)-$(VERSION).tar.gz $(PACKAGE)-$(VERSION)
	rm -f dist.files
	rm -rf $(PACKAGE)-$(VERSION)

clean:
	rm -f lua/rima_*_core.so
	rm -f htmldocs/*.html
	rm -f $(PACKAGE)-$(VERSION).tar.gz
	rm -f lua/luacov.*.out

