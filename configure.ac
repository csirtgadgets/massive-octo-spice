#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.64])
AC_INIT(cif, m4_esyscmd([./version.sh]), m4_esyscmd([( cat .issuetracker )| tr -d "\n"]))
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
AC_SUBST(CIF_VERSION,AC_PACKAGE_VERSION)
AC_SUBST(CIF_VERSION_MAJOR,      ${cif_version_major})
AC_SUBST(CIF_VERSION_MINOR,      ${cif_version_minor})
AC_SUBST(CIF_VERSION_PATCH,      ${cif_version_patch})
AC_SUBST(CIF_VERSION_META,       ${cif_version_meta})

AC_SUBST(CIF_PROTOCOL_VERSION,  m4_esyscmd([( cat .protocol_version ) | tr -d "\n"]))
AC_SUBST(ORG,'csirtgadgets.org')
AC_SUBST(DEFAULT_PORT, 4961)

AC_PROG_INSTALL

# perl stuff
AC_ARG_VAR([PERL],[Perl interpreter command])
AC_PATH_PROG([PERL], [perl], [not found])
if test "$PERL" = 'not found'; then
    AC_MSG_ERROR([cannot use $PACKAGE_NAME without perl])
fi 

AC_ARG_VAR([CPANM],[cpanminus app])
AC_PATH_PROG([CPANM],[cpanm],[not found])
AM_CONDITIONAL(HAVE_CPANM, test "x$CPANM" != 'not found')

AC_PATH_PROG([CURL],[curl],[not found])
if test "$CURL" = 'not found'; then
    AC_MSG_ERROR([curl required to configure elasticsearch...])
fi

AC_ARG_ENABLE(perl-critic, AC_HELP_STRING(--enable-perl-critic, Enable Perl::Critic in testing @<:@default=no@:>@),
    enable_perl_critic=$enableval, enable_perl_critic="no")

if test x$enable_perl_critic = xyes; then
    AC_SUBST(PERL_CRITIC,1)
fi

AC_ARG_VAR([ES_HOST],[ElasticSearch Host])
AC_ARG_WITH(es-host,
    AC_HELP_STRING([--with-es-host=ES_HOST],
        [elastic search host @<:@default=localhost:9200@:>@]),
        ES_HOST=$withval,
        ES_HOST='localhost:9200')
AC_SUBST(ES_HOST)

AC_CONFIG_FILES([
    Makefile
    libcif/Makefile.PL
    libcif/lib/CIF/Generated.pm
    router/Makefile.PL
    smrt/Makefile.PL
    schema/Makefile
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

#TODO make this configurable
if test "x$prefix" != xNONE; then
    AC_SUBST(CIF_PATH, `eval "echo ${prefix}"`)
else
    AC_SUBST(CIF_PATH, `eval "echo ${ac_default_prefix}"`)
fi

AC_SUBST(siteperldir, `eval "echo ${CIF_PATH}/lib/perl5"`)

if test "x$sysconfdir" == 'x${prefix}/etc'; then
    AC_SUBST(ext_sysconfdir, `eval "echo ${CIF_PATH}/etc"`)
else
    AC_SUBST(ext_sysconfdir, `eval "echo $sysconfdir"`)
fi

if test "x$localstatedir" == 'x${prefix}/var'; then
    AC_SUBST(ext_localstatedir, `eval "echo ${CIF_PATH}/var"`)
else
    AC_SUBST(ext_localstatedir, `eval "echo $localstatedir"`)
fi

AC_OUTPUT
