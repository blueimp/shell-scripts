# Docker development environment

## Description
This project provides a convenient docker development environment.  
It comes preconfigured with the following container services:

* nginx
* php
* redis
* mongodb
* elasticsearch

## Setup

### Requirements

Program        | Version
-------------- | -------
docker         | 1.10+
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

### Use aliases to execute commands in docker containers:

```sh
php --version

phpunit --version

composer --version

redis-cli --version

mongo --version

mongorestore --version

mongodump --version
```

#### Command Working directory
The working directory for a binary is set to that of its container,
e.g. `/srv/www` for the php container and its php binaries.  
As a result, we have to take this working directory into account, e.g.:

```sh
composer status -d dev.test
```

## License
Released under the [MIT license](http://opensource.org/licenses/MIT).

## Author
[Sebastian Tschan](https://blueimp.net/)
