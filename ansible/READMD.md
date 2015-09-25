This is an initial protoype of using Ansible to install and configure cifv2; in of itself it isn't that interesting as this prototype Ansible code does the exact same thing as the BASH easy_button.sh does currently. What's interesting is the potential using a configuration management system gives us. 

Examples:

1. Creating Ansible Playbooks for each primary role that exsists in cifv2. This would allow easy configiration of a distributed cifv2 installation as well as combining those playbooks for a all-in-one install. The anticiapted roles will be:
 * cif-starman
 * cif-router
 * cif-worker
 * cif-smart
 * ElasticSearch
1. Creating ansible playbooks that facilitate installing on Debian/Ubuntu or Redhat/CentOS. Here's an example of how this could be done:
 * Using ```when: ansible_os_family``` as seen in this [playbook](https://github.com/geerlingguy/ansible-role-postfix/blob/master/tasks/main.yml) to choose what [package manager](http://docs.ansible.com/ansible/yum_module.html) and [repo's](https://www.elastic.co/guide/en/elasticsearch/reference/1.4/setup-repositories.html) to use. 
