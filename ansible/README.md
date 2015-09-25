This is an initial prototype of using Ansible to install and configure cifv2; in of itself
this prototype isn't that interesting as it does the exact same thing as the
easy_button.sh does currently. What's interesting is the potential using a configuration
management system gives us.

== Examples ==

1. Creating Ansible Playbooks for each primary role that exsists in cifv2. This would
facilitate easy configuration of a distributed cifv2 install as well as combining those
playbooks for a all-in-one install. The anticipated roles are:
 * cif-starman
 * cif-router
 * cif-worker
 * cif-smrt
 * ElasticSearch
1. Creating ansible playbooks that assist in installing cifv2 on Debian/Ubuntu or
Redhat/CentOS. Here's an example of how this could be done:
 * Using ```when: ansible_os_family``` as seen in this [playbook](https://github.com/geerlingguy/ansible-role-postfix/blob/master/tasks/main.yml) to choose what [package manager](http://docs.ansible.com/ansible/yum_module.html) and [repo's](https://www.elastic.co/guide/en/elasticsearch/reference/1.4/setup-repositories.html) to use.

Usage:

All-in-one install

1. Starting with a clean install of Ubuntu 14.04 64-bit
1. Bash the EasyButton!
```curl -Ls https://raw.githubusercontent.com/csirtgadgets/massive-octo-spice/develop/ansible/ansible_easybutton.sh | sudo bash -```

Using a Ansible server and a clean install of Ubuntu 14.04 64-bit on a second host.

1. Update the remote_user in massive-octo-spice/ansible/ansible.cfg
1. Update the IP address for cif-ansible-host01 in massive-octo-spice/ansible/hosts
1. Run the following commands:
```
$ cd /srv/massive-octo-spice/ansible
$ ansible-playbook cif-ansible-host01
```

Todo:
1. Additional testing
1. Refacter roles to support RHEL/CentOS
1. Look into breaking out the roles into the major CIF services
1. Clean up general Ansible inconsistencies (i.e. improve this initial prototype)
