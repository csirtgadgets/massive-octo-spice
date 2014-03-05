#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.64])
AC_INIT(libcif, m4_esyscmd([( cat ../.version )| tr -d "\n"]), m4_esyscmd([( cat ../.issuetracker )| tr -d "\n"]))
AM_INIT_AUTOMAKE

AC_PREFIX_DEFAULT([/opt/cif])

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

AC_SUBST(CIF_PROTOCOL_VERSION,  m4_esyscmd([( cat ../.protocol_version ) | tr -d "\n"]))

# Checks for programs.
AC_ARG_VAR([PERL],[Perl interpreter command])
AC_PATH_PROG([PERL], [perl], [not found])
if test "$PERL" = 'not found'; then
    AC_MSG_ERROR([cannot use $PACKAGE_NAME without perl])
fi

# setup
m4_include([m4/layout.m4])
CIF_ENABLE_LAYOUT

AC_CONFIG_FILES([
    Makefile
])

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

AC_SUBST([CIF_PATH], ${prefix})
AC_SUBST([CIF_SMRT_PATH], ${exp_smrtdir})
AC_SUBST([CIF_ROUTER_PATH], ${exp_routerdir})

AC_CONFIG_FILES([
    lib/CIF.pm
    lib/CIF/Generated.pm
])

AC_OUTPUT
