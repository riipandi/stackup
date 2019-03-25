#!/usr/bin/env python

from setuptools import setup

with open("readme.md", "r") as fh:
    long_description = fh.read()

setuptools.setup(
    name='elsa',
    version='2.5',
    author="Aris Ripandi",
    author_email="aris@ripandi.id",
    description="StackUp commandline utility",
    long_description=open("readme.md").read(),
    long_description_content_type="text/markdown",
    url="https://github.com/riipandi/stackup",
    packages=setuptools.find_packages(),
    scripts=['elsa'] ,
    install_requires=[
        'requests', 'click', 'configparser', 'certbot'
    ],
    classifiers=[
        "Programming Language :: Python :: 3 :: Only",
        "License :: OSI Approved :: Apache Software License",
        "Operating System :: POSIX :: Linux",
        "Topic :: System :: Systems Administration",
    ],
)
