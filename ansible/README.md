# Introduction

This is an initial prototype of using Ansible to install and configure
a multi-node CIFv2 installation. If you are creating a single node
all-in-one you should use the [easy install
script](https://github.com/csirtgadgets/massive-octo-spice/wiki/PlatformUbuntu)
as it has been throughly tested.

## Example Four node CIFv2 installation

### Setting up the Environment

1. Build four Ubuntu 14.04.3 64-bit Server machines using the following specifications:
  * CIF node: CPU: x, Mem: y, Disk: Z
  * ES nodes: CPU: x, Mem: y, Disk: Z
1. Build and [install](http://docs.ansible.com/ansible/intro_installation.html) Ansible on a management host
  * Ansible node: CPU: 1 core, Mem: 1024MB, Disk: 8GB
1. SSH into the management host
1. Clone the CIFv2 repository to the management host

  ```bash
  cd ~/
  git clone https://github.com/csirtgadgets/massive-octo-spice.git
  ```
1. Configure the Ansible hosts file with the IP addresses of the four nodes you built previously

  ```bash
  cd ~/massive-octo-spice/ansible
  vim hosts
  ```
  Update the following with the correct IP addresses:
  ```
  [cif_server]
  cif ansible_ssh_host=192.168.1.205

  [elastic_search]
  es01 ansible_ssh_host=192.168.1.201
  es02 ansible_ssh_host=192.168.1.202
  es03 ansible_ssh_host=192.168.1.203
  ```

1. Create a ssh key to be used by Ansible

  ```bash
  <todo>
  ```
1. Copy over ssh keys

  ```bash
  ssh-copy-id -i ~/.ssh/id_rsa.pub ansible@192.168.1.201
  ssh-copy-id -i ~/.ssh/id_rsa.pub ansible@192.168.1.202
  ssh-copy-id -i ~/.ssh/id_rsa.pub ansible@192.168.1.203
  ssh-copy-id -i ~/.ssh/id_rsa.pub ansible@192.168.1.205
  ```
1. Build ElasticSearch Cluster

  ```bash
  ansible-playbook -K elasticsearch.yml
  ```
1. Build CIF Server

  ```bash
  ansible-playbook -K cif.yml
  ```

### Testing

1. SSH into cif01
  ```bash
  ssh <username>@192.168.1.205
  ```

1. Verify the ElasticSearch cluster is setup correctly

  ```bash
  ssh <username>@192.168.1.205
$ curl 'http://192.168.1.201:9200/_cluster/health?pretty'
{
  "cluster_name" : "elasticsearch",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 3,
  "number_of_data_nodes" : 3,
  "active_primary_shards" : 10,
  "active_shards" : 20,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0
}
  ```

1. test connectivity to the router 
 
  ```bash
  $ cif -p
  roundtrip: 0.518286 ms
  roundtrip: 0.487317 ms
  roundtrip: 0.47499 ms
  roundtrip: 0.518493 ms
  ```
1. perform an initial `cif-smrt` test run  

  ```bash
  $ sudo service monit stop
  $ sudo service cif-smrt stop
  $ sudo -u cif /opt/cif/bin/cif-smrt --testmode
  [2014-10-21T15:17:10,668Z][INFO][main:322]: cleaning up tmp: /var/smrt/cache
  [2014-10-21T15:17:10,691Z][DEBUG][main:294]: id4.us - ssh
  [2014-10-21T15:17:10,691Z][INFO][main:295]: processing: /opt/cif/bin/cif-smrt -d -r /etc/cif/rules/default/1d4_us.yml -f ssh
  [2014-10-21T15:17:10,692Z][INFO][CIF::Smrt:92]: starting at: 2014-10-21T00:00:00Z
  [2014-10-21T15:17:10,692Z][DEBUG][CIF::Smrt:97]: fetching...
  ...
  ```
1. re-start cif-smrt  

  ```bash
  $ sudo service cif-smrt start
  $ sudo service monit start
  ```

1. test out a query:

  ```bash
  $ cif --cc US
  $ cif --cc CN
  $ cif --tags scanner --cc us
  $ cif --otype ipv4 --cc cn
  ```

## All-in-one install

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
