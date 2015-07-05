# nginx+php+redis+mongodb+elasticsearch with docker

## Requirements

Before starting the setup process, please install the following software:

### docker

For Mac OS X, please see
[blueimp/boot2docker](https://github.com/blueimp/boot2docker).

For other operating systems, please follow the official
[docker documentation](http://docs.docker.com/installation/).

### docker-compose

Please follow the official
[docker-compose documentation](http://docs.docker.com/compose/install/).

## Setup

### Generate a self-signed SSL certificate for nginx:

```sh
mkdir -p secrets/ssl

openssl req -nodes -new -x509 \
	-keyout secrets/ssl/dev.test.key \
	-out secrets/ssl/dev.test.crt
```

### Generate the SSH keypair and known hosts file for git access:

```sh
mkdir -p secrets/ssh

ssh-keygen -t rsa -C deploy -N "" -f secrets/ssh/id_rsa

ssh-keyscan -t rsa github.com $(dig +short github.com) \
  >> secrets/ssh/known_hosts
ssh-keyscan -t rsa bitbucket.org $(dig +short bitbucket.org) \
  >> secrets/ssh/known_hosts
```

### Create the environment variables config file:

```sh
echo '
# Each line of the expenv configuration must have the following format:
# VARIABLE_NAME command [args...]
# Examples:
# PASSWORD echo secret
# KEY cat path/to/key_file
# Empty lines and lines starting with a hash (#) will be ignored.

SSMTP_AUTH_USER echo mail@dev.test
SSMTP_AUTH_PASS echo password

SSL_CRT cat secrets/ssl/dev.test.crt
SSL_KEY cat secrets/ssl/dev.test.key

SSH_PRIVATE_KEY cat secrets/ssh/id_rsa
SSH_PUBLIC_KEY cat secrets/ssh/id_rsa.pub
SSH_KNOWN_HOSTS cat secrets/ssh/known_hosts
' > .expenv
```

### Build the docker development images:

```sh
./bin/build.sh
```

### Create the web directory:

```sh
mkdir ../web
```

### Source the environment variables and command aliases:

```sh
. .env
```

### Start the development environment:

```sh
docker-compose up -d
```

### Update the hosts file with the development hostname:

```sh
./bin/hostnames.sh
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

Released under the [MIT license](http://www.opensource.org/licenses/MIT).

## Author

[Sebastian Tschan](https://blueimp.net/)
