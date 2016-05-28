# Docker development environment

## Description
This project provides a sample docker development environment.

## Setup

### Requirements

Program        | Version
-------------- | -------
docker         | 1.9+
docker-compose | 1.6+

### Secrets generation
See [SECRETS](SECRETS.md) for the secrets generation.

### Source the environment variables and command aliases:

```sh
. .env
```

### Build the docker development images:

```sh
app-build-docker-images
```

### Create the web directory:

```sh
mkdir -p ../web
```

### Start the development environment:

```sh
docker-compose up -d
```

### Update the hosts file with the development hostname:

```sh
app-hostnames
```

### Open the development website:

```sh
open https://dev.test/
```

## License
Released under the [MIT license](http://opensource.org/licenses/MIT).

## Author
[Sebastian Tschan](https://blueimp.net/)
