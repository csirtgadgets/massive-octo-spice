#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.64])
AC_INIT(cif, m4_esyscmd([( cat .version )| tr -d "\n"]), m4_esyscmd([( cat .issuetracker )| tr -d "\n"]))
AM_INIT_AUTOMAKE

dnl Save our incant early since $@ gets overwritten by some macros.
dnl ${ac_configure_args} is available later, but it's quoted differently
dnl and undocumented.  See http://www.spinics.net/lists/ac/msg10022.html.
AC_SUBST(CONFIGURE_INCANT, "$0 $@")

AC_PREFIX_DEFAULT([/opt/cif])
# setup
m4_include([m4/layout.m4])
m4_include([m4/ax_check_user.m4])
m4_include([m4/ax_check_group.m4])

AC_SUBST([cif_version_major],
    m4_bregexp(AC_PACKAGE_VERSION,[^\(\w+\)\.\(\w+\)\.\(\w+\)-?\(\w+\.\d+\)?],[\1]))
AC_SUBST([cif_version_minor],
    m4_bregexp(AC_PACKAGE_VERSION,[^\(\w+\)\.\(\w+\)\.\(\w+\)-?\(\w+\.\d+\)?],[\2]))
AC_SUBST([cif_version_patch],
    m4_bregexp(AC_PACKAGE_VERSION,[^\(\w+\)\.\(\w+\)\.\(\w+\)-?\(\w+\.\d+\)?],[\3]))
AC_SUBST([cif_version_meta],
    m4_bregexp(AC_PACKAGE_VERSION,[\(-\S+\)$],[\1]))
test "x$cif_version_major" = 'x' && cif_version_major=0
test "x$cif_version_minor" = 'x' && cif_version_minor=0
test "x$cif_version_patch" = 'x' && cif_version_patch=0
test "x$cif_version_meta"  = 'x' && cif_version_meta=''

dnl version numbers
AC_SUBST(CIF_VERSION_MAJOR,      ${cif_version_major})
AC_SUBST(CIF_VERSION_MINOR,      ${cif_version_minor})
AC_SUBST(CIF_VERSION_PATCH,      ${cif_version_patch})
AC_SUBST(CIF_VERSION_META,       ${cif_version_meta})

AC_SUBST(CIF_PROTOCOL_VERSION,  m4_esyscmd([( cat .protocol_version ) | tr -d "\n"]))
AC_SUBST(ORG,'csirtgadgets.org')
AC_SUBST(DEFAULT_PORT, 4961)

#dnl CIF_USER
AC_ARG_WITH(user,
    AC_HELP_STRING([--with-user=USER],
        [user the cif scripts will run as (default: cif)]),
    CIF_USER=$withval,
    CIF_USER=cif)
AC_SUBST(CIF_USER)

#dnl CIF_GROUP
AC_ARG_WITH(group,
    AC_HELP_STRING([--with-group=GROUP],
        [group the cif scripts will run as (default: cif)]),
    CIF_GROUP=$withval,
    CIF_GROUP=$CIF_USER
)
AC_SUBST(CIF_GROUP)

AX_CHECK_USER(USER,[$CIF_USER],no)
if test x$USER = xno; then
    AC_MSG_ERROR([$CIF_USER user does not exist, it must be created first])
fi

AX_CHECK_GROUP(GROUP,[$CIF_GROUP],no)
if test x$GROUP = xno; then
    AC_MSG_ERROR([$CIF_GROUP group does not exist, it must first be created])
fi  

AC_PROG_INSTALL
AC_PATH_PROG([WGET],[wget],[not found])
AC_PATH_PROG([SHA1SUM],[sha1sum],[not found])
AC_ARG_VAR([PERL],[Perl interpreter command])
AC_PATH_PROG([PERL], [perl], [not found])
if test "$PERL" = 'not found'; then
    AC_MSG_ERROR([cannot use $PACKAGE_NAME without perl])
fi 

#AC_ARG_VAR([DEVMODE])
#AC_ARG_ENABLE(devmode, AC_HELP_STRING(--enable-devmode, Enable development mode (user/group=vagrant, --enable-embedded) @<:@default=no@:>@),
#    enable_devmode=$enableval, enable_devmode="no")
#AM_CONDITIONAL(DEVMODE, test x$enable_devmode = xyes)

AC_ARG_VAR([ES_HOST],[ElasticSearch Host])
AC_ARG_WITH(es-host,
    AC_HELP_STRING([--with-es-host=ES_HOST],
        [elastic search host @<:@default=localhost:9200@:>@]),
        ES_HOST=$withval,
        ES_HOST='localhost:9200')
AC_SUBST(ES_HOST)

# for elastic search
AC_ARG_ENABLE(embedded, AC_HELP_STRING(--enable-embedded, Enable embedded support for ElasticSearch (requires java) @<:@default=no@:>@),
    enable_embedded=$enableval, enable_embedded="no")

if test x$enable_embedded = xyes; then 
    AC_PATH_PROG([CURL],[curl],[not found])
    if test "$CURL" = 'not found'; then
        AC_MSG_ERROR([curl required to configure elasticsearch...])
    fi
    AC_PATH_PROG([JAVA], [java], [not found])
    if test "$JAVA" = 'not found'; then
        AC_MSG_ERROR([cannot use $PACKAGE_NAME without java (ElasticSearch)])
    fi
    AC_CONFIG_FILES([
        extern/elasticsearch/Makefile
        extern/elasticsearch/elasticsearch.yml
        extern/kibana/Makefile
        extern/kibana/contrib/kibana-nginx.conf
    ])
fi
AM_CONDITIONAL(HAVE_EMBEDDED, test x$enable_embedded = xyes)

CIF_ENABLE_LAYOUT

AC_CONFIG_SUBDIRS([
])

AC_CONFIG_FILES([
    Makefile
    libcif/Makefile
    libcif/lib/CIF/Generated.pm
    libcif/bin/cif
    router/Makefile
    router/bin/cif-router
    smrt/Makefile
    smrt/bin/cif-smrt
    extern/Makefile
    schema/Makefile
])

dnl layout paths
AC_SUBST([CIF_PATH],         ${exp_prefix})

AC_SUBST([CIF_SMRT_PATH], ${exp_smrtdir})
AC_SUBST([CIF_ROUTER_PATH], ${exp_routerdir})

AC_OUTPUT
