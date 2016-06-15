# Docker tools

## Description
A collection of POSIX compatible shell scripts as additions to a Docker based
development environment.

## Tools

### docker-build-images.sh
Builds images for each Dockerfile found recursively in the current directory.  
Also accepts Dockerfiles and directories to search for as arguments.

```sh
./docker-build-images.sh [Dockerfile|directory] [...]
```

Tags images based on git branch names, with `master` being tagged as `latest`.  
Resolves image dependencies for images in the same project.

### docker-hostnames.sh
Updates hostnames for the docker host IP or `127.0.0.1` in `/etc/hosts`.

```sh
./docker-hostnames.sh [-d] [config_file_1] [config_file_2] [...]
```

### docker-image-cleanup.sh
Removes dangling docker images.

```sh
./docker-image-cleanup.sh
```

### docker-image-exists.sh
Checks if a given docker image exists.

```sh
./docker-image-exists.sh image[:tag]
```

### docker-machine-bridge.sh
Adds a bridged network adapter to a VirtualBox docker machine.

```sh
./docker-machine-bridge.sh [-i network_adapter] [-d] [machine]
```

## License
Released under the [MIT license](http://opensource.org/licenses/MIT).

## Author
[Sebastian Tschan](https://blueimp.net/)
