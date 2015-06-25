# nginx+php+redis+mongodb+elasticsearch with docker

## Requirements

Before starting the setup process, install the following software:

### docker

For Mac OS X, please see [blueimp/boot2docker](https://github.com/blueimp/boot2docker).

For other operating systems, please follow the official [docker installation instructions](http://docs.docker.com/installation/).

### docker-compose

Please follow the official [docker compose installation instructions](http://docs.docker.com/compose/install/).

## Setup

### Generate a self-signed SSL certificate for nginx:

```sh
mkdir -p secrets/ssl

openssl req -nodes -new -x509 \
	-keyout secrets/ssl/dev.test.key \
	-out secrets/ssl/dev.test.crt
```

### Generate SSH keypair and known hosts file for git access:

```sh
mkdir -p secrets/ssh

ssh-keygen -t rsa -C deploy -N "" -f secrets/ssh/id_rsa

ssh-keyscan github.com >> secrets/ssh/known_hosts
ssh-keyscan bitbucket.org >> secrets/ssh/known_hosts
```

### Create the secrets environment config:

```sh
echo -n '# Absolute path to the secrets dir:
SECRETS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

export SSMTP_AUTH_USER="mail@dev.test"
export SSMTP_AUTH_PASS="password"

export SSL_CRT=$(cat "$SECRETS_DIR"/ssl/dev.test.crt)
export SSL_KEY=$(cat "$SECRETS_DIR"/ssl/dev.test.key)

export SSH_PRIVATE_KEY=$(cat "$SECRETS_DIR"/ssh/id_rsa)
export SSH_PUBLIC_KEY=$(cat "$SECRETS_DIR"/ssh/id_rsa.pub)
export SSH_KNOWN_HOSTS=$(cat "$SECRETS_DIR"/ssh/known_hosts)
' > secrets/.env
```

### Edit SSMTP configuration settings (skip {{PLACEHOLDER}} values):

```sh
nano develop/secretconfig/ssmtp.conf
```

### Build the docker development images:

```sh
./develop/build.sh
```

### Create the web directory:

```sh
mkdir ../web
```

### Start the development environment:

```sh
source .env

docker-compose up -d
```

### Update the hosts file and open the development website:

```sh
./scripts/update-hosts.sh dev.test

open https://dev.test/
```

### Use php, phpunit, composer, redis-cli, mongo, mongorestore, mongodump:

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

The working directory for a binary is set to that of its container, e.g. `/srv/www` for the php container and its php binaries.  
As a result, we have to take this working directory into account when executing the commands, e.g.:

```sh
composer status -d dev.test
```

## License

Released under the [MIT license](http://www.opensource.org/licenses/MIT).

## Author

[Sebastian Tschan](https://blueimp.net/)
