This is an initial prototype of using Ansible to install and configure cifv2; in of itself
this prototype isn't that interesting as it does the exact same thing as the
easy_button.sh does currently. What's interesting is the potential using a configuration
management system gives us.

## Examples

1. Creating Ansible Playbooks for each primary role that exsists in cifv2. This would
facilitate easy configuration of a distributed cifv2 install as well as combining those
playbooks for a all-in-one install. The anticipated roles are:
 * CIF
  * cif-starman
  * cif-router
  * cif-worker
  * cif-smrt
 * ElasticSearch

### Three node build

[process is under development]

1. Configure Ansible hosts file with two ElasticSearch nodes and one CIF node
1. Copy over ssh keys

  ```bash
  - ssh-copy-id -i ~/.ssh/id_rsa.pub ansible@192.168.1.205
  - ssh-copy-id -i ~/.ssh/id_rsa.pub ansible@192.168.1.201
  - ssh-copy-id -i ~/.ssh/id_rsa.pub ansible@192.168.1.202
  ```
1. Build ElasticSearch Cluster

  ```bash
  ansible-playbook -K elasticsearch.yml
  ```
1. Build CIF Server
  ```bash
  ansible-playbook -K cif.yml
  ```

### All-in-one install

[process is under development]

1. Starting with a clean install of Ubuntu 14.04 64-bit
1. Bash the EasyButton!
  ```bash
  curl -Ls https://raw.githubusercontent.com/csirtgadgets/massive-octo-spice/develop/ansible/ansible_easybutton.sh | sudo bash -
  ```

Using a Ansible server and a clean install of Ubuntu 14.04 64-bit on a second host.

1. Update the remote_user in massive-octo-spice/ansible/ansible.cfg
1. Update the IP address for cif-ansible-host01 in massive-octo-spice/ansible/hosts
1. Run the following commands:

  ```basih
  $ cd /srv/massive-octo-spice/ansible
  $ ansible-playbook cif-ansible-host01
  ```

Todo:

1. Additional testing
1. Look into breaking out the roles into the major CIF services
1. Clean up general Ansible inconsistencies (i.e. improve this initial prototype)
