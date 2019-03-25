import click

@click.command()
@click.option('--upgrade', '-u')
def main():
    click.echo("{}, {}".format(greeting, name))
