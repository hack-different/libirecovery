AM_CPPFLAGS = \
	-I$(top_srcdir)/include

AM_CFLAGS = \
	$(GLOBAL_CFLAGS) \
	$(LFS_CFLAGS) \
	$(PTHREAD_CFLAGS)

AM_LIBS = \
	$(PTHREAD_LIBS)

if HAVE_CYTHON

BUILT_SOURCES = irecovery.c

CLEANFILES = \
	*.pyc \
	*.pyo \
	irecovery.c

EXTRA_DIST = \
	irecovery.pyx \
	irecovery.pxd

irecoverydir = $(pyexecdir)
irecovery_LTLIBRARIES = irecovery.la
irecovery_la_SOURCES = irecovery.pyx
irecovery_la_CFLAGS = \
	-I$(top_srcdir)/include \
	-I$(top_srcdir)/src \
	$(PYTHON_CPPFLAGS) \
	$(AM_CFLAGS) \
	-Wno-shadow \
	-Wno-redundant-decls \
	-Wno-switch-default \
	-Wno-strict-aliasing \
	-Wno-implicit-function-declaration \
	-fvisibility=default \
	$(CYTHON_CFLAGS)

irecovery_la_LDFLAGS = \
	-module \
	-avoid-version \
	-L$(libdir) \
	$(PYTHON_LIBS) \
	$(PYTHON_EXTRA_LIBS) \
	$(AM_LIBS) \
	-no-undefined

irecovery_la_LIBADD = $(top_builddir)/src/libirecovery-1.0.la

irecovery.c: irecovery.pyx irecovery.pxd

.pyx.c:
	$(CYTHON) -I$(CYTHON_PLIST_INCLUDE_DIR) -I$(top_srcdir)/src -o $@ $<

endif