echo 'setting up bind...'

if [ -z `grep -l '8.8.8.8' /etc/bind/named.conf.options` ]; then
    echo 'overwriting bind config'
    cp /etc/bind/named.conf.options /etc/bind/named.conf.options.orig
    cp named.conf.options /etc/bind/named.conf.options
fi

if [ -z `grep -l 'spamhaus.org' /etc/bind/named.conf.local` ]; then
    cat ./named.conf.local >> /etc/bind/named.conf.local
fi

echo 'restarting bind...'
service bind9 restart

if [ -z `grep -l '^prepend domain-name-servers 127.0.0.1;' /etc/dhcp/dhclient.conf` ]; then
    cp dhclient.conf /etc/dhcp/
fi

if [ -z `grep -l '127.0.0.1' /etc/resolvconf/resolv.conf.d/base` ]; then
    echo 'adding 127.0.0.1 as nameserver'
    echo "nameserver 127.0.0.1" >> /etc/resolvconf/resolv.conf.d/base
    echo "restarting network..."
    ifdown eth0 && sudo ifup eth0
fi