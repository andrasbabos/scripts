## short description

The purpose of this Powershell script is to export or import monitoring policies data from BMC's TrueSight monitoring into a json file. The json files are used as backups or can be stored in version control.

The script will connect via REST API to the given URL's with the given users, no other special requirement like extra modules.

## how to use

The script have builtin help, you can access it with:

    get-help .\manage-policy.ps1

The input variables precedence is

1. input via command line parameter
2. read from config file
3. ask during script execution

Fill in the config.ini file with the variables which you like and comment out the rest with # sign, and these will be asked or need to be defined via command line parameter.

### Examples

List all policies:

    .\manage-policy.ps1 -command list

Export a policy:

    .\manage-policy.ps1 -command export -policyname "my_policy_name" -username my_user -password my_password -exportdir c:\Users\my_user\Documents\tsom\dump\
