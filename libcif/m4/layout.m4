dnl Copyright (C) 1994, 1995-8, 1999, 2001 Free Software Foundation, Inc.
dnl This file is free software; the Free Software Foundation
dnl gives unlimited permission to copy and/or distribute it,
dnl with or without modifications, as long as this notice is preserved.

dnl This program is distributed in the hope that it will be useful,
dnl but WITHOUT ANY WARRANTY, to the extent permitted by law; without
dnl even the implied warranty of MERCHANTABILITY or FITNESS FOR A
dnl PARTICULAR PURPOSE.

dnl
dnl @synopsis CIF_ENABLE_LAYOUT()
dnl
dnl Enable a specific directory layout for the installation to use.
dnl This configures a command-line parameter that can be specified
dnl at ./configure invocation.
dnl
dnl The use of this feature in this way is a little hackish, but
dnl better than a heap of options for every directory.
dnl
dnl This code is heavily borrowed *cough* from the Apache 2 code.
dnl

AC_DEFUN([CIF_ENABLE_LAYOUT],[
AC_ARG_ENABLE(layout,
          AC_HELP_STRING([--enable-layout=LAYOUT],
                     [Use a specific directory layout (Default: relative)]),
          LAYOUT=$enableval)

if test "x$LAYOUT" = "x"; then
    LAYOUT="relative"
fi
CIF_LAYOUT($srcdir/config.layout, $LAYOUT)
AC_MSG_CHECKING(for chosen layout)
if test "x$cif_layout_name" = "xno"; then
    if test "x$LAYOUT" = "xno"; then
        AC_MSG_RESULT(none)
    else
        AC_MSG_RESULT($LAYOUT)
    fi
    AC_MSG_ERROR([a valid layout must be specified (or the default used)])
else
    AC_SUBST(cif_layout_name)
    AC_MSG_RESULT($cif_layout_name)
fi
if test "x$cif_layout_name" != "xinplace" ; then
    AC_SUBST([COMMENT_INPLACE_LAYOUT], [""])
else
    AC_SUBST([COMMENT_INPLACE_LAYOUT], [# ])
fi
])

dnl
dnl @synopsis CIF_LAYOUT(configlayout, layoutname)
dnl
dnl This macro reads an Apache-style layout file (specified as the
dnl configlayout parameter), and searches for a specific layout
dnl (named using the layoutname parameter).
dnl
dnl The entries for a given layout are then inserted into the
dnl environment such that they become available as substitution
dnl variables. In addition, the cif_layout_name variable is set
dnl (but not exported) if the layout is valid.
dnl
dnl This code is heavily borrowed *cough* from the Apache 2 codebase.
dnl

AC_DEFUN([CIF_LAYOUT],[
    if test ! -f $srcdir/config.layout; then
        AC_MSG_WARN([Layout file $srcdir/config.layout not found])
        cif_layout_name=no
    else
        pldconf=./config.pld
        $PERL  -0777 -p -e "\$layout = '$2';"  -e '
        s/.*<Layout\s+$layout>//gims; 
        s/\<\/Layout\>.*//s; 
        s/^#.*$//m;
        s/^\s+//gim;
        s/\s+$/\n/gim;
        s/\+$/\/cif/gim;
        # m4 will not let us just use $1, we need @S|@1
        s/^\s*((?:bin|sbin|libexec|data|sysconf|sharedstate|localstate|lib|include|oldinclude|info|man|router|smrt|libcif)dir)\s*:\s*(.*)$/@S|@1=@S|@2/gim;
        s/^\s*(.*?)\s*:\s*(.*)$/\(test "x\@S|@@S|@1" = "xNONE" || test "x\@S|@@S|@1" = "x") && @S|@1=@S|@2/gim;
         ' < $1 > $pldconf

        if test -s $pldconf; then
            cif_layout_name=$2
            . $pldconf
            changequote({,})
            for var in prefix exec_prefix bindir sbindir \
                 sysconfdir mandir libdir datadir \
                 localstatedir logfiledir \
                 sessionstatedir customdir custometcdir \
                 customlexdir customstaticdir customplugindir customlibdir manualdir \
                 routerdir routerlibdir smrtdir smrtlibdir libcifdir libciflibdir; do
                eval "val=\"\$$var\""
                val=`echo $val | sed -e 's:\(.\)/*$:\1:'`
                val=`echo $val | 
                    sed -e 's:[\$]\([a-z_]*\):${\1}:g'`
                eval "$var='$val'"
            done
            changequote([,])
        else
            cif_layout_name=no
        fi
        #rm $pldconf
    fi
    CIF_SUBST_EXPANDED_ARG(prefix)
    CIF_SUBST_EXPANDED_ARG(exec_prefix)
    CIF_SUBST_EXPANDED_ARG(bindir)
    CIF_SUBST_EXPANDED_ARG(sbindir)
    CIF_SUBST_EXPANDED_ARG(sysconfdir)
    CIF_SUBST_EXPANDED_ARG(mandir)
    CIF_SUBST_EXPANDED_ARG(libdir)
    CIF_SUBST_EXPANDED_ARG(datadir)
    CIF_SUBST_EXPANDED_ARG(manualdir)
    CIF_SUBST_EXPANDED_ARG(plugindir)
    CIF_SUBST_EXPANDED_ARG(localstatedir)
    CIF_SUBST_EXPANDED_ARG(logfiledir)
    CIF_SUBST_EXPANDED_ARG(customdir)
    CIF_SUBST_EXPANDED_ARG(custometcdir)
    CIF_SUBST_EXPANDED_ARG(customplugindir)
    CIF_SUBST_EXPANDED_ARG(customstaticdir)
    CIF_SUBST_EXPANDED_ARG(customlibdir)
    CIF_SUBST_EXPANDED_ARG(smrtdir)
    CIF_SUBST_EXPANDED_ARG(routerdir)
])dnl

dnl
dnl @synopsis   CIF_SUBST_EXPANDED_ARG(var)
dnl
dnl Export (via AC_SUBST) a given variable, along with an expanded
dnl version of the variable (same name, but with exp_ prefix).
dnl
dnl This code is heavily borrowed *cough* from the Apache 2 source.
dnl

AC_DEFUN([CIF_SUBST_EXPANDED_ARG],[
    CIF_EXPAND_VAR(exp_$1, [$]$1)
    AC_SUBST($1)
    AC_SUBST(exp_$1)
])

dnl
dnl @synopsis   CIF_EXPAND_VAR(baz, $fraz)
dnl
dnl Iteratively expands the second parameter, until successive iterations
dnl yield no change. The result is then assigned to the first parameter.
dnl
dnl This code is heavily borrowed from the Apache 2 codebase.
dnl

AC_DEFUN([CIF_EXPAND_VAR],[
    ap_last=''
    ap_cur='$2'
    while test "x${ap_cur}" != "x${ap_last}"; do
        ap_last="${ap_cur}"
        ap_cur=`eval "echo ${ap_cur}"`
    done
    $1="${ap_cur}"
])
