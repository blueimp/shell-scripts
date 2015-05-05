# nginx+php+redis+mongodb with docker

## Requirements

Before starting the setup process, install the following software:

### docker

For Mac OS X, please see [blueimp/boot2docker](https://github.com/blueimp/boot2docker).

For other operating systems, please follow the official [docker installation instructions](http://docs.docker.com/installation/#installation).

### docker-compose

Please follow the official [docker compose installation instructions](http://docs.docker.com/compose/install/#install-compose).

## Setup

### Generate a self-signed SSL certificate for nginx:

```sh
mkdir develop/nginx/ssl

openssl req -nodes -new -x509 \
	-keyout develop/nginx/ssl/dev.test.key \
	-out develop/nginx/ssl/dev.test.crt
```

### Generate SSH keypair and known hosts file for git access:

```sh
mkdir develop/php/ssh

ssh-keygen -t rsa -C docker -N "" -f develop/php/ssh/id_rsa

ssh-keyscan github.com >> develop/php/ssh/known_hosts
```

### Edit SSMTP configuration settings (except AuthPass):

```sh
nano develop/php/ssmtp.conf
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
docker-compose up -d
```

### Update the hosts file and open the development website:

```sh
./update-hosts.sh dev.test

open https://dev.test/
```

### Use mongorestore, mongodump, php, phpunit and composer:

```sh
source .env

mongorestore --version

mongodump --version

php --version

phpunit --version

composer status -d dev.test
```

## License

Released under the [MIT license](http://www.opensource.org/licenses/MIT).

## Author

[Sebastian Tschan](https://blueimp.net/)
