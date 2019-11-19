## dvd store isntall

This is an ansible playbook to install DVD Store 2.1 on SLES 11 servers for burn-in test execution.

It's not a generally usable role like on Ansible Galaxy, but it can be useful for ideas how to automate the task.

I wrote it after a 2 day Ansible Essentials course for my specific goal but I plan on learning more and write a full DVD Store 3 ansible role in the future.

### how to use

Read carefully the playbook, there are a lot of little settings there like zabbix agent for monitoring which you probably don't need.

These are the custom files compared to the original dvdstore git repository:

* Install_DVDStore_una.pl - commented ot the part where it ask for parameters and the default parameters are used at the beginning of the script, modify these values before execution.
* dsbrowse.php - there is a ' character in one of the person names in the source text files, this makes sql command error because the string not escaped in the php code. I added a pg_escape_string function at line 111. so the name is properly escaped.
