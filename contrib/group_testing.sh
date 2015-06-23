#!/bin/bash

# v.01
# 
# To use this script you must do the following:
# 1. Generate a user in a group named "group01" with read and write permissions
# - /opt/cif/bin/cif-tokens --new --username john.smith@example.com --read --write --groups group01
#
# 2. Copy and paste this new users token into the variable "GROUP01_TOKEN" below
#
# 3. Copy and paste the user "root@localhost" token into the variable "EVERYONE_TOKEN" below 


GROUP01_TOKEN=''
EVERYONE_TOKEN=''

FQDN='larry.com'
URL='http://larry.com'
IPV4='1.1.1.254'
EMAIL='larry@larry.com'
IPV6='2001:4860:4860::8888'
HASH='5d818df91298b218d0890874da7b7cb9910105ff'

CIF_CMD='/usr/local/bin/cif --no-verify-ssl --remote 'https://localhost''

## add data ##

#add fqdn
echo '{"observable":"'$FQDN'","tlp":"amber","confidence":"85","tags":"malware","provider":"me.com","group":"group01"}' | $CIF_CMD -s --token $GROUP01_TOKEN
if [ $? != 0 ]; then echo "Error: adding fqdn"; fi

#add url
echo '{"observable":"'$URL'","tlp":"amber","confidence":"85","tags":"malware","provider":"me.com","group":"group01"}' | $CIF_CMD -s --token $GROUP01_TOKEN
if [ $? != 0 ]; then echo "Error: adding url"; fi

#add ipv4
echo '{"observable":"'$IPV4'","tlp":"amber","confidence":"85","tags":"malware","provider":"me.com","group":"group01"}' | $CIF_CMD -s --token $GROUP01_TOKEN
if [ $? != 0 ]; then echo "Error: adding ipv4"; fi

#add email
echo '{"observable":"'$EMAIL'","tlp":"amber","confidence":"85","tags":"malware","provider":"me.com","group":"group01"}' | $CIF_CMD -s --token $GROUP01_TOKEN
if [ $? != 0 ]; then echo "Error: adding email"; fi

#add ipv6
echo '{"observable":"'$IPV6'","tlp":"amber","confidence":"85","tags":"malware","provider":"me.com","group":"group01"}' | $CIF_CMD -s --token $GROUP01_TOKEN
if [ $? != 0 ]; then echo "Error: adding ipv6"; fi

#add hash
echo '{"observable":"'$HASH'","tlp":"amber","confidence":"85","tags":"malware","provider":"me.com","group":"group01"}' | $CIF_CMD -s --token $GROUP01_TOKEN
if [ $? != 0 ]; then echo "Error: adding hash"; fi


## verify data exists for group01 ##

#verify fqdn
tmp=`$CIF_CMD --token $GROUP01_TOKEN -c 85 -q $FQDN -f csv | grep $FQDN`
if [ $? != 0 ]; then echo "ERROR: $FQDN does not exist for group01"; fi

#verify url
tmp=`$CIF_CMD --token $GROUP01_TOKEN -c 85 -q $URL -f csv | grep $URL`
if [ $? != 0 ]; then echo "ERROR: $URL does not exist for group01"; fi

#verify ipv4
tmp=`$CIF_CMD --token $GROUP01_TOKEN -c 85 -q $IPV4 -f csv | grep $IPV4`
if [ $? != 0 ]; then echo "ERROR: $IPV4 does not exist for group01"; fi

#verify email
tmp=`$CIF_CMD --token $GROUP01_TOKEN -c 85 -q $EMAIL -f csv | grep $EMAIL`
if [ $? != 0 ]; then echo "ERROR: $EMAIL does not exist for group01"; fi

#verify ipv6
tmp=`$CIF_CMD --token $GROUP01_TOKEN -c 85 -q $IPV6 -f csv | grep $IPV6`
if [ $? != 0 ]; then echo "ERROR: $IPV6 does not exist for group01"; fi

#verify hash
tmp=`$CIF_CMD --token $GROUP01_TOKEN -c 85 -q $HASH -f csv | grep $HASH`
if [ $? != 0 ]; then echo "ERROR: $HASH does not exist for group01"; fi


## verify data does not exist for everyone group ##

#verify fqdn
tmp=`$CIF_CMD --token $EVERYONE_TOKEN -c 85 -q $FQDN -f csv | grep $FQDN`
if [ $? != 1 ]; then echo "ERROR: $FQDN does exist for everyone group"; fi
 
#verify url 
tmp=`$CIF_CMD --token $EVERYONE_TOKEN -c 85 -q $URL -f csv | grep $URL`
if [ $? != 1 ]; then echo "ERROR: $URL does exist for everyone group"; fi 
#verify ipv4
tmp=`$CIF_CMD --token $EVERYONE_TOKEN -c 85 -q $IPV4 -f csv | grep $IPV4`
if [ $? != 1 ]; then echo "ERROR: $IPV4 does exist for everyone group"; fi 

#verify email
tmp=`$CIF_CMD --token $EVERYONE_TOKEN -c 85 -q $EMAIL -f csv | grep $EMAIL`
if [ $? != 1 ]; then echo "ERROR: $EMAIL does exist for everyone group"; fi
 
#verify ipv6
tmp=`$CIF_CMD --token $EVERYONE_TOKEN -c 85 -q $IPV6 -f csv | grep $IPV6`
if [ $? != 1 ]; then echo "ERROR: $IPV6 does exist for everyone group"; fi
 
#verify hash
tmp=`$CIF_CMD --token $EVERYONE_TOKEN -c 85 -q $HASH -f csv | grep $HASH`
if [ $? != 1 ]; then echo "ERROR: $HASH does exist for everyone group"; fi


## verify data exists in feeds for group01

#verify fqdn
tmp=`$CIF_CMD --token $GROUP01_TOKEN --feed --otype fqdn -c 85 -f csv | grep $FQDN`
if [ $? != 0 ]; then echo "ERROR: $FQDN does not exist for group01 in fqdn feed"; fi 

#verify ipv4
tmp=`$CIF_CMD --token $GROUP01_TOKEN --feed --otype ipv4 -c 85 -f csv | grep $IPV4`
if [ $? != 0 ]; then echo "ERROR: $IPV4 does not exist for group01 in ipv4 feed"; fi 

#verify ipv6
tmp=`$CIF_CMD --token $GROUP01_TOKEN --feed --otype ipv6 -c 85 -f csv | grep $IPV6`
if [ $? != 0 ]; then echo "ERROR: $IPV6 does not exist for group01 in ipv6 feed"; fi 

#verify url
tmp=`$CIF_CMD --token $GROUP01_TOKEN --feed --otype url -c 85 -f csv | grep $URL`
if [ $? != 0 ]; then echo "ERROR: $URL does not exist for group01 in url feed"; fi 

#verify email
tmp=`$CIF_CMD --token $GROUP01_TOKEN --feed --otype email -c 85 -f csv | grep $EMAIL`
if [ $? != 0 ]; then echo "ERROR: $EMAIL does not exist for group01 in email feed"; fi 

## verify data does not exist in feeds for everyone

#verify fqdn
tmp=`$CIF_CMD --token $EVERYONE_TOKEN --feed --otype fqdn -c 85 -f csv | grep $FQDN`
if [ $? != 1 ]; then echo "ERROR: $FQDN does exist for everyone in fqdn feed"; fi

#verify ipv4
tmp=`$CIF_CMD --token $EVERYONE_TOKEN --feed --otype ipv4 -c 85 -f csv | grep $IPV4`
if [ $? != 1 ]; then echo "ERROR: $IPV4 does not exist for everyone in ipv4 feed"; fi 

#verify ipv6
tmp=`$CIF_CMD --token $EVERYONE_TOKEN --feed --otype ipv6 -c 85 -f csv | grep $IPV6`
if [ $? != 1 ]; then echo "ERROR: $IPV6 does not exist for everyone in ipv6 feed"; fi 

#verify url
tmp=`$CIF_CMD --token $EVERYONE_TOKEN --feed --otype url -c 85 -f csv | grep $URL`
if [ $? != 1 ]; then echo "ERROR: $URL does not exist for everyone in url feed"; fi 

#verify email
tmp=`$CIF_CMD --token $EVERYONE_TOKEN --feed --otype email -c 85 -f csv | grep $EMAIL`
if [ $? != 1 ]; then echo "ERROR: $EMAIL does not exist for everyone in email feed"; fi 
