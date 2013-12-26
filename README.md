benchmarks
==========

repository for benchmark scripts and such

Idea
----------

This is (going) to be a set of scripts helping to 
build a test environment and test your Galera setups.
We are using  [ansible](http://www.ansibleworks.com/) to 
automate and distribute tasks.
You don't need to log on any of the nodes as you are going to manage
your cluster/testing from you local machine.
So this repo is going to be your working directory for your ongoing 
tasks.

There are 4/5 modules planed

* Provisioning (not implemented)
* Installation (ongoing)
* Testing      (ongoing)
* Visualising  (not implemented)

### Provisioning
This module is going to help you to launch instances in
AWS or an OpenStack environment.

### Installation
This module/scripts are going to install and configure you a 
* Galera cluster
* Deploys the testing script on a separate machine

Now (20131226) you are going to have a cluster of $yournumber of 
galera nodes with $yournumber of testing/sysbench nodes pointing
to *one* of the galera nodes.

We are going to support the Debian(Ubuntu) and RedHat OS family.
Regarding Galera you can choose between Codership, MariaDB, Percona.
( Right now only  Codership is supported on RehHat)

### Testing
While you can install your testing hosts. We use sysbench 0.5 for the 
testing. You can invoke the script standalone or just run a (so called) play.
Starting a play/test run you can configure your galera settings. 
A rolling restart is done for you automatically and result is stored in your
/tmp directory

#### Format
The result is written in yaml and include
* SHOW GLOBAL VARIABLES
* SHOW GLOBAL STATUS (before and after each sysbench test)
* sysbench results
It is planned to put to put the environment (virtualisation and (ansible -m setup))
informations into that yaml to. (Maybe we switch to json also)
The idea is to have as much informations about a run as we need even for
later investigation.


### Visualising
This is about extracting and visualise the informations. 
BIG TODO



WARNING
============
This is work in progress. It is going to be changed on a daily basis :)
