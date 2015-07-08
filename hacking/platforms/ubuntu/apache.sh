. /etc/lsb-release

VER=$DISTRIB_RELEASE

echo 'setting up apache'
if [ ! -f /etc/apache2/cif.conf ]; then
    /bin/cp cif.conf /etc/apache2/
fi

if [ $VER == "12.04" ]; then
    cp /etc/apache2/sites-available/default-ssl /etc/apache2/sites-available/default-ssl.orig
    cp default-ssl /etc/apache2/sites-available
    a2dissite default
    a2ensite default-ssl
    sed -i 's/^ServerTokens OS/ServerTokens Prod/' /etc/apache2/conf.d/security
    sed -i 's/^ServerSignature On/#ServerSignature On/' /etc/apache2/conf.d/security
    sed -i 's/^#ServerSignature Off/ServerSignature Off/' /etc/apache2/conf.d/security
elif [ $VER == "14.04" ]; then
    cp /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf.orig
    cp default-ssl /etc/apache2/sites-available/default-ssl.conf
    a2dissite 000-default.conf
    a2ensite default-ssl.conf
    sed -i 's/^ServerTokens OS/ServerTokens Prod/' /etc/apache2/conf-enabled/security.conf
    sed -i 's/^ServerSignature On/#ServerSignature On/' /etc/apache2/conf-enabled/security.conf
    sed -i 's/^#ServerSignature Off/ServerSignature Off/' /etc/apache2/conf-enabled/security.conf

    if [ ! -f /etc/apache2/conf-available/servername.conf ]; then
        echo "ServerName localhost" >> /etc/apache2/conf-available/servername.conf
        a2enconf servername
    fi
fi

a2enmod ssl proxy proxy_http