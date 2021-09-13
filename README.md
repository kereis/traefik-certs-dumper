# traefik-certs-dumper

[![Docker Pulls](https://img.shields.io/docker/pulls/humenius/traefik-certs-dumper?logo=docker&style=flat)](https://hub.docker.com/r/humenius/traefik-certs-dumper)
[![Docker Image Version (latest semver)](https://img.shields.io/docker/v/humenius/traefik-certs-dumper?sort=semver&style=flat)](https://hub.docker.com/r/humenius/traefik-certs-dumper)
[![MicroBadger Size (tag)](https://img.shields.io/microbadger/image-size/humenius/traefik-certs-dumper/latest?label=size%20%28latest%29&logo=docker)](https://hub.docker.com/r/humenius/traefik-certs-dumper)
![MicroBadger Size (tag)](https://img.shields.io/microbadger/image-size/humenius/traefik-certs-dumper/alpine?label=size%20%28alpine%29&logo=docker)
![GitHub Workflow Status](https://img.shields.io/github/workflow/status/humenius/traefik-certs-dumper/build-docker-images?label=Docker%20build&logo=github)
![GitHub Workflow Status (Alpine)](https://img.shields.io/github/workflow/status/humenius/traefik-certs-dumper/build-alpine-images?label=Alpine%20build&logo=github)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/e448ef74f4c9456dae00d75914499990)](https://www.codacy.com/gh/humenius/traefik-certs-dumper/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=humenius/traefik-certs-dumper&amp;utm_campaign=Badge_Grade)

Dumps Let's Encrypt certificates of a specified domain to `.pem` and `.key` files which Traefik stores in `acme.json`.

This image uses:
- a bash script that derivates from [mailu/traefik-certdumper](https://hub.docker.com/r/mailu/traefik-certdumper)
- [ldez's traefik-certs-dumper](https://github.com/ldez/traefik-certs-dumper)

Special thanks to them!

**IMPORTANT**: It's supposed to work with Traefik **v2** or higher! If you want to use this certificate dumper with **v1**, you can simply change the image to [mailu/traefik-certdumper](https://hub.docker.com/r/mailu/traefik-certdumper).

## Table Of Content
- [traefik-certs-dumper](#traefik-certs-dumper)
  - [Table Of Content](#table-of-content)
  - [Usage](#usage)
    - [Image choice](#image-choice)
      - [`alpine` notes!](#alpine-notes)
    - [Basic setup](#basic-setup)
    - [Dump all certificates](#dump-all-certificates)
    - [Automatic container restart](#automatic-container-restart)
    - [Change ownership of certificate and key files](#change-ownership-of-certificate-and-key-files)
    - [Extract multiple domains](#extract-multiple-domains)
    - [Health Check](#health-check)
    - [Merging private key and public certificate in one .pem](#merging-private-key-and-public-certificate-in-one-pem)
    - [Merging private key and public certificate in one PKCS12 file](#merging-private-key-and-public-certificate-in-one-pkcs12-file)
  - [Help!](#help)

## Usage
### Image choice
We ship various flavors of this image - multi-arch, Docker (default) and Alpine. The versioning follows [SemVer](https://semver.org/).

|                     | amd64 (normal)           | arm32v7 | arm64v8 |
|---------------------|--------------------------|-----|-----|
| **Docker (normal)** | `latest`, `x.x.x`, `x.x`, `x` | `arm32v7`, `x.x.x-arm32v7`, `x.x-arm32v7`, `x-arm32v7` | `arm64v8`,`x.x.x-arm64v8`, `x.x-arm64v8`, `x-arm64v8` |
| **Alpine**          | `alpine`, `x.x.x-alpine`, `x.x-alpine`, `x-alpine` | `arm32v7-alpine`, `x.x.x-arm32v7-alpine`, `x.x-arm32v7-alpine`, `x-arm32v7-alpine` | `arm64v8-alpine`,`x.x.x-arm64v8-alpine`, `x.x-arm64v8-alpine`, `x-arm64v8-alpine` |

#### `alpine` notes!
Please note that when using the `alpine` variant, using the container restart functionality won't work due to missing Docker installation and will be skipped.

### Basic setup
Mount your ACME folder into `/traefik` and output folder to `/output`. Here's an example for docker-compose:
```yaml
version: '3.7'

services:
  certdumper:
    image: humenius/traefik-certs-dumper:latest
    volumes:
    - ./traefik/acme:/traefik:ro
    - ./output:/output:rw
    environment:
    - DOMAIN=example.org
```

### Dump all certificates
The environment variable `DOMAIN` can be left out if you want to dump all available certificates.
```yaml
version: '3.7'

services:
  certdumper:
    image: humenius/traefik-certs-dumper:latest
    volumes:
    - ./traefik/acme:/traefik:ro
    - ./output:/output:rw
    # Don't set DOMAIN
    # environment:
    # - DOMAIN=example.org
```

### Automatic container restart
If you want to have containers restarted after dumping certificates into your output folder, you can specify their names as comma-separated value and pass them through via optional parameter `-r | --restart-containers`. In this case, you must pass the Docker socket (or override `$DOCKER_HOST` if you use a Docker socket proxy). For instance:
```yaml
version: '3.7'

services:
  certdumper:
    image: humenius/traefik-certs-dumper:latest
    command: --restart-containers container1,container2,container3
    volumes:
    - ./traefik/acme:/traefik:ro
    - ./output:/output:rw
    - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
    - DOMAIN=example.org
```

It is also possible to restart Docker services. You can specify their names exactly like the containers via the optional parameter `--restart-services`. The services are updated with the command `docker service update --force <service_name>` which restarts all tasks in the service.

### Change ownership of certificate and key files
If you want to change the onwership of the certificate and key files because your container runs on different permissions than `root`, you can specify the UID and GID as an environment variable. These environment variables are `OVERRIDE_UID` and `OVERRIDE_GID`. These can only be integers and must both be set for the override to work. For instance:
```yaml
version: '3.7'

services:
  certdumper:
    image: humenius/traefik-certs-dumper:latest
    command: --restart-containers container1,container2,container3
    volumes:
    - ./traefik/acme:/traefik:ro
    - ./output:/output:rw
    - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
    - DOMAIN=example.org
    - OVERRIDE_UID=1000
    - OVERRIDE_GID=1000
```

### Extract multiple domains
This Docker image is able to extract multiple domains as well.
Use environment variable `DOMAIN` and add you domains as a comma-separated list.
After certificate dumping, the certificates can be found in the domains' subdirectories respectively.
(`/output/DOMAIN[i]/...`)
If you specify a single domain, the output folder remains the same as in previous versions (< v1.3 - `/output`).
```yaml
version: '3.7'

services:
  certdumper:
    image: humenius/traefik-certs-dumper:latest
    volumes:
    - ./traefik/acme:/traefik:ro
    - ./output:/output:rw
    - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      DOMAIN: example.com,example.org,example.net,hello.example.in
```

### Health Check
This Docker image does reports its health status.
The process which monitors `run.sh` reports back `1` when it malfunctions and `0` when it is running inside Docker container.
Normally, it's embedded in the Dockerfile which means without further ado, this works out of the box. However, if you want to specify more than one health check, you can set them via `docker-compose`.
```yaml
version: '3.7'

services:
  certdumper:
    image: humenius/traefik-certs-dumper:latest
    volumes:
    - ./traefik/acme:/traefik:ro
    - ./output:/output:rw
    - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      DOMAIN: example.com,example.org,example.net,sub.domain.ext
    healthcheck:
      test: ["CMD", "/usr/bin/healthcheck"]
      interval: 30s
      timeout: 10s
      retries: 5
```

### Merging private key and public certificate in one .pem
Load balancers like [HAProxy](http://www.haproxy.org/) need both private key and public certificate to be concatenated to one file. In this case, you can set the environment variable `COMBINED_PEM` to a desired file name ending with file extension `*.pem`. Each time `traefik-certs-dumper` dumps the certificates for specified `DOMAIN`, this script will create a `*.pem` file named after `COMBINED_PEM` in each domain's folder respectively.
```yaml
version: '3.7'

services:
  certdumper:
    image: humenius/traefik-certs-dumper:latest
    volumes:
    - ./traefik/acme:/traefik:ro
    - ./output:/output:rw
    - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      DOMAIN: example.com,example.org,example.net,hello.example.in
      COMBINED_PEM: my_concatted_file.pem
```

### Merging private key and public certificate in one PKCS12 file

Some applications like [Plex](https://www.plex.tv/de/) need both private key and public certificate to be concatenated to one PKCS12 file. In this case, you can set the environment variable `COMBINE_PKCS12` to any value (In Docker, no value means not setting. Must be atleast "".). Each time `traefik-certs-dumper` dumps the certificates for specified `DOMAIN`, this script will create a file named `cert.p12` in each domain's folder respectively. The password can be set with the environment variable `PKCS12_PASSWORD` which has support for docker secrets with the `PKCS12_PASSWORD_FILE` environment variable. If none of those is set, the password will be empty.

```yaml
version: '3.7'

services:
  certdumper:
    image: humenius/traefik-certs-dumper:latest
    container_name: traefik_certdumper
    network_mode: none
    volumes:
      - ./traefik/acme:/traefik:ro
      - ./output:/output:rw
      - /var/run/docker.sock:/var/run/docker.sock:ro
    secrets:
      - pkcs12_password
    environment:
      DOMAIN: $DOMAINNAME0
      PKCS12_PASSWORD_FILE: /run/secrets/pkcs12_password
      COMBINE_PKCS12: "true"
      OVERRIDE_UID: 1000
      OVERRIDE_GID: 1000

secrets:
  pkcs12_password:
    file: /path/to/secret/PKCS12_PASSWORD
```

## Help!
If you need help using this image, have suggestions or want to report a problem, feel free to open an issue on GitHub!
