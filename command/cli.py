#!/usr/bin/env python
#
# This is a small cli utilities for managing your server.
#

import os
import click

# Privilages check
if os.getuid() is not 0:
    print("You aren't root!")
    exit(1)

# Update and upgrade the system
# os.system('apt update ; apt full-upgrade -y')
# os.system('apt autoremove -y ; apt clean')

@click.command()
@click.argument('name')
@click.option('--greeting', '-g')
def main(name, greeting):
    click.echo("{}, {}".format(greeting, name))

if __name__ == "__main__":
    main()
