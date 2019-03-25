import os
import click

@click.command()
@click.argument('name')
@click.option('--upgrade', '-u')
def main():
    os.system('apt update ; apt full-upgrade -y')
    os.system('apt autoremove -y ; apt clean')

