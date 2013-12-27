Playbooks
========

Here you got so called Plays/Playbook (ansible speak) for testing and installing an 
environment.

There are Playbooks bundling the modularized tasks
* multi_install.yaml
* multi_test.yaml

multi_install.yaml
-----------------
Installs your galera cluster and testing nodes

multi_test.yaml
---------------
Does deploy your configuration and a rolling restart of the cluster.
After that a test run is done.
This will (default) a schema with 5 table a 1000000 rows and do some testings.



