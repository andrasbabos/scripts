#!/usr/bin/python
import os

filepath = '/usr/local/etc/restricted_user/' + os.getlogin() + '.txt'

with open(filepath, 'r') as f:
    allowed_commands = f.readlines()

orig_cmd = os.environ['SSH_ORIGINAL_COMMAND']

if orig_cmd in allowed_commands:
    os.system(orig_cmd)
