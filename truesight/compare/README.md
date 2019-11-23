## short description

The purpose of this Powershell script is to export server's data from BMC's TrueSight monitoring and CMDB to a csv file. Each server will be one line in the file, the TSOM and CMDB data next to each other, this way it's possible to check the data in both sources.

The script will connect via REST API to the given URL's with the given users, no other special requirement.

## how to use

Fill in the variables.ps1 for the usernames, passwords and servernames then execute the script. 
