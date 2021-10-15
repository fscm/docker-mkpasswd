# mkpasswd for Docker

A small image that can be used to run the `mkpasswd` tool from the
[whois](https://github.com/rfc1036/whois) project.

## Supported tags

- [`latest`](https://github.com/fscm/docker-mkpasswd/blob/master/Dockerfile)

## What is mkpasswd?

> mkpasswd tool encrypts a given password with the crypt(3) libc function using a given salt.

## Getting Started

There are a couple of things needed for the script to work.

### Prerequisites

Docker, either the Community Edition (CE) or Enterprise Edition (EE), needs to
be installed on your local computer.

#### Docker

Docker installation instructions can be found
[here](https://docs.docker.com/install/).

### Usage

To start a container with this image and run the tool (in interactive mode) use
the following command (the container will be deleted after exiting the shell):

```shell
docker container run --rm --interactive --tty fscm/mkpasswd
```

To do the same in a non-interactive node add the password that you wish to
encrypt at the end of the previous command, like so:

```shell
docker container run --rm --interactive --tty fscm/mkpasswd my_password
```

By default, the `mkpasswd` tool will encrypt the password with the 'Yescrypt'
method.

To view a list of the available methods use the following command:

```shell
docker container run --rm --interactive --tty fscm/mkpasswd -m help
```

To view a list of all of the available options use the following command:

```shell
docker container run --rm --interactive --tty fscm/mkpasswd --help
```

## Build

Build instructions can be found
[here](https://github.com/fscm/docker-mkpasswd/blob/master/README.build.md).

## Versioning

This project uses [SemVer](http://semver.org/) for versioning. For the versions
available, see the [tags on this repository](https://github.com/fscm/docker-mkpasswd/tags).

## Authors

- **Frederico Martins** - [fscm](https://github.com/fscm)

See also the list of [contributors](https://github.com/fscm/docker-mkpasswd/contributors)
who participated in this project.
