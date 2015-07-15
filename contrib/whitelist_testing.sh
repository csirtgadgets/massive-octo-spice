#!/bin/bash

# v.01
# 
# To use this script you must do the following:
#
# 1. Copy and paste the user "root@localhost" token into the variable "EVERYONE_TOKEN" below 


EVERYONE_TOKEN=''

FQDN='bobby.com'
URL='http://bobby.com'
IPV4='1.1.1.253'
EMAIL='bobby@bobby.com'
IPV6='2001:4860:4860::8844'
HASH='a95dc1fe39dbcb3f5e615b9d229ec433'

CIF_CMD='/usr/local/bin/cif --no-verify-ssl --remote 'https://localhost''

## add mock threat data ##

#add fqdn
echo '{"observable":"'$FQDN'","tlp":"amber","confidence":"85","tags":"malware","provider":"me.com","group":"everyone"}' | $CIF_CMD -s --token $EVERYONE_TOKEN
if [ $? != 0 ]; then echo "Error: adding fqdn"; fi

#add url
echo '{"observable":"'$URL'","tlp":"amber","confidence":"85","tags":"malware","provider":"me.com","group":"everyone"}' | $CIF_CMD -s --token $EVERYONE_TOKEN
if [ $? != 0 ]; then echo "Error: adding url"; fi

#add ipv4
echo '{"observable":"'$IPV4'","tlp":"amber","confidence":"85","tags":"malware","provider":"me.com","group":"everyone"}' | $CIF_CMD -s --token $EVERYONE_TOKEN
if [ $? != 0 ]; then echo "Error: adding ipv4"; fi

#add email
echo '{"observable":"'$EMAIL'","tlp":"amber","confidence":"85","tags":"malware","provider":"me.com","group":"everyone"}' | $CIF_CMD -s --token $EVERYONE_TOKEN
if [ $? != 0 ]; then echo "Error: adding email"; fi

#add ipv6
echo '{"observable":"'$IPV6'","tlp":"amber","confidence":"85","tags":"malware","provider":"me.com","group":"everyone"}' | $CIF_CMD -s --token $EVERYONE_TOKEN
if [ $? != 0 ]; then echo "Error: adding ipv6"; fi

#add hash
echo '{"observable":"'$HASH'","tlp":"amber","confidence":"85","tags":"malware","provider":"me.com","group":"everyone"}' | $CIF_CMD -s --token $EVERYONE_TOKEN
if [ $? != 0 ]; then echo "Error: adding hash"; fi


## verify data exists for everyone group ##

#verify fqdn
tmp=`$CIF_CMD --token $EVERYONE_TOKEN -c 85 -q $FQDN -f csv | grep '$FQDN'`
if [ $? != 1 ]; then echo "ERROR: $FQDN does not exist for everyone group"; fi

#verify url
tmp=`$CIF_CMD --token $EVERYONE_TOKEN -c 85 -q $URL -f csv | grep '$URL'`
if [ $? != 1 ]; then echo "ERROR: $URL does not exist for everyone group"; fi

#verify ipv4
tmp=`$CIF_CMD --token $EVERYONE_TOKEN -c 85 -q $IPV4 -f csv | grep '$IPV4'`
if [ $? != 1 ]; then echo "ERROR: $IPV4 does not exist for everyone group"; fi

#verify email
tmp=`$CIF_CMD --token $EVERYONE_TOKEN -c 85 -q $EMAIL -f csv | grep '$EMAIL'`
if [ $? != 1 ]; then echo "ERROR: $EMAIL does not exist for everyone group"; fi

#verify ipv6
tmp=`$CIF_CMD --token $EVERYONE_TOKEN -c 85 -q $IPV6 -f csv | grep '$IPV6'`
if [ $? != 1 ]; then echo "ERROR: $IPV6 does not exist for everyone group"; fi

#verify hash
tmp=`$CIF_CMD --token $EVERYONE_TOKEN -c 85 -q $HASH -f csv | grep '$HASH'`
if [ $? != 1 ]; then echo "ERROR: $HASH does not exist for everyone group"; fi


## add whitelist data ##

#add fqdn
echo '{"observable":"'$FQDN'","tlp":"amber","confidence":"100","tags":"whitelist","provider":"csirtgadgets.org","group":"everyone"}' | $CIF_CMD -s --token $EVERYONE_TOKEN
if [ $? != 0 ]; then echo "Error: adding fqdn"; fi

#add url
echo '{"observable":"'$URL'","tlp":"amber","confidence":"100","tags":"whitelist","provider":"csirtgadgets.org","group":"everyone"}' | $CIF_CMD -s --token $EVERYONE_TOKEN
if [ $? != 0 ]; then echo "Error: adding url"; fi

#add ipv4
echo '{"observable":"'$IPV4'","tlp":"amber","confidence":"100","tags":"whitelist","provider":"csirtgadgets.org","group":"everyone"}' | $CIF_CMD -s --token $EVERYONE_TOKEN
if [ $? != 0 ]; then echo "Error: adding ipv4"; fi

#add email
echo '{"observable":"'$EMAIL'","tlp":"amber","confidence":"100","tags":"whitelist","provider":"csirtgadgets.org","group":"everyone"}' | $CIF_CMD -s --token $EVERYONE_TOKEN
if [ $? != 0 ]; then echo "Error: adding email"; fi

#add ipv6
echo '{"observable":"'$IPV6'","tlp":"amber","confidence":"100","tags":"whitelist","provider":"csirtgadgets.org","group":"everyone"}' | $CIF_CMD -s --token $EVERYONE_TOKEN
if [ $? != 0 ]; then echo "Error: adding ipv6"; fi

#add hash
echo '{"observable":"'$HASH'","tlp":"amber","confidence":"100","tags":"whitelist","provider":"csirtgadgets.org","group":"everyone"}' | $CIF_CMD -s --token $EVERYONE_TOKEN
if [ $? != 0 ]; then echo "Error: adding hash"; fi


## verify data is not in feed after whitelist ##

#verify fqdn
tmp=`$CIF_CMD --token $EVERYONE_TOKEN --feed --otype fqdn -c 85 -f csv | grep '$FQDN'`
if [ $? != 1 ]; then echo "ERROR: $FQDN does exist for everyone in fqdn feed"; fi

#verify ipv4
tmp=`$CIF_CMD --token $EVERYONE_TOKEN --feed --otype ipv4 -c 85 -f csv | grep '$IPV4'`
if [ $? != 1 ]; then echo "ERROR: $IPV4 does not exist for everyone in ipv4 feed"; fi

#verify ipv6
tmp=`$CIF_CMD --token $EVERYONE_TOKEN --feed --otype ipv6 -c 85 -f csv | grep '$IPV6'`
if [ $? != 1 ]; then echo "ERROR: $IPV6 does not exist for everyone in ipv6 feed"; fi

#verify url
tmp=`$CIF_CMD --token $EVERYONE_TOKEN --feed --otype url -c 85 -f csv | grep '$URL'`
if [ $? != 1 ]; then echo "ERROR: $URL does not exist for everyone in url feed"; fi

#verify email
tmp=`$CIF_CMD --token $EVERYONE_TOKEN --feed --otype email -c 85 -f csv | grep '$EMAIL'`
if [ $? != 1 ]; then echo "ERROR: $EMAIL does not exist for everyone in email feed"; fi

