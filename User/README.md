User Specific Stuff
==================

In this directory you manage your personal configurations.
This is another approach to manage your infrastructure.
You got
* Manage your conf.d
* Use a configuration file


Manage your conf.d
------------------
We drop an recreate /etc/mysql/conf.d
and fill the directory with all files ending with .cnf
from the conf.d directora here.
Feel free to do your MySQL/Galera configuration in here


Use a configuration file
-----------------------

Instead of setting and overwriting Options via the --extra-vars Option
you can use user_configuration_vars.yaml in this directory to set your
configurations also.
Remind it is a yaml file
