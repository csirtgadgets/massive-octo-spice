# check for existing iptables rules
if [[ -z $(iptables --list-rules | egrep -v '(-P INPUT ACCEPT|-P FORWARD ACCEPT|-P OUTPUT ACCEPT)') ]]; then
    #check to see if ufw is enabled (active) 
    if [[ $(ufw status | grep "Status: inactive") ]]; then
        # Enable firewall if it is determined there are no iptable
        # rules or ufw is disabled. 
        echo "Configuring basic firewall rules"
        echo "Configuring firewall to allow SSH from anywhere"
        /usr/sbin/ufw allow ssh
        echo "Configuring firewall to allow HTTPS from anywhere"
        /usr/sbin/ufw allow https
        echo "Enabling firewall"
        /usr/sbin/ufw --force enable
    else
        echo "INFO: UFW appears to be enabled, skipping firewall configuration"
    fi
else
    echo "INFO: There are existing IPTABLES firewall rules, skipping firewall configuration"
fi