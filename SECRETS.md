# Secrets generation

This guide generates the secrets used in the container services.

## Generate a self-signed SSL certificate for nginx:

```sh
mkdir ssl

openssl req -nodes -x509 -newkey rsa:2048 \
  -subj '/C=/ST=/L=/O=/OU=/CN=dev.test' \
  -keyout ssl/default.key \
  -out ssl/default.crt

openssl dhparam -out ssl/dhparam.pem 2048
```

The last command generates the Diffie-Hellman Ephemeral Parameters for stronger
forward secrecy. See also
[Strong SSL Security on nginx](https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html)
and the section "Forward Secrecy & Diffie Hellman Ephemeral Parameters".

## Create the secrets config file:

```sh
echo '
export DH_PARAM="$(cat ssl/dhparam.pem)"
export SSL_CRT="$(cat ssl/default.crt)"
export SSL_KEY="$(cat ssl/default.key)"
' > .secrets
```
