# traefik-certs-dumper <!-- omit in toc -->

[![GitHub license](https://img.shields.io/github/license/kereis/traefik-certs-dumper)](https://github.com/kereis/traefik-certs-dumper/blob/develop/LICENSE)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/e448ef74f4c9456dae00d75914499990)](https://www.codacy.com/gh/kereis/traefik-certs-dumper/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=kereis/traefik-certs-dumper&amp;utm_campaign=Badge_Grade)

---
> ## ⚠️ ATTENTION!
>
> This image has been moved and will be released to ghcr.io. Newer releases are now tagged as `ghcr.io/kereis/traefik-certs-dumper`.
---

Dumps Let's Encrypt certificates of a specified domain to `.pem` and `.key` files which Traefik stores in `acme.json`.

This image uses:

- a bash script that derivates from [mailu/traefik-certdumper](https://hub.docker.com/r/mailu/traefik-certdumper)
- [ldez's traefik-certs-dumper](https://github.com/ldez/traefik-certs-dumper)

Special thanks to them!

**IMPORTANT**: It's supposed to work with Traefik **v2** or higher! If you want to use this certificate dumper with **v1**, you can simply change the image to [mailu/traefik-certdumper](https://hub.docker.com/r/mailu/traefik-certdumper).

> ### Old stats
>
> [![Docker Pulls](https://img.shields.io/docker/pulls/humenius/traefik-certs-dumper?logo=docker&style=flat)](https://hub.docker.com/r/humenius/traefik-certs-dumper)
> ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/humenius/traefik-certs-dumper/1.6.1?label=image%20size%20%281.6.1%29&logo=docker)
> ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/humenius/traefik-certs-dumper/1.6.1-alpine?label=image%20size%20%281.6.1-alpine%29&logo=docker)
>
> ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/humenius/traefik-certs-dumper/1.6.1-arm64v8?label=image%20size%20%281.6.1-arm64v8%29&logo=docker)
> ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/humenius/traefik-certs-dumper/1.6.1-arm64v8-alpine?label=image%20size%20%281.6.1-arm64v8-alpine%29&logo=docker)
>
> ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/humenius/traefik-certs-dumper/1.6.1-arm32v7?label=image%20size%20%281.6.1-arm32v7%29&logo=docker)
> ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/humenius/traefik-certs-dumper/1.6.1-arm32v7-alpine?label=image%20size%20%281.6.1-arm32v7-alpine%29&logo=docker)

---

## Table of Contents <!-- omit in toc -->

<!--ts-->
- [Usage](#usage)
  - [Image choice](#image-choice)
  - [Environment Variables](#environment-variables)
  - [Basic setup](#basic-setup)
  - [Dump all certificates](#dump-all-certificates)
  - [Custom ACME file name](#custom-acme-file-name)
  - [Automatic container restart](#automatic-container-restart)
  - [Change ownership of certificate and key files](#change-ownership-of-certificate-and-key-files)
  - [Extract multiple domains](#extract-multiple-domains)
  - [Health Check](#health-check)
  - [Merging private key and public certificate in one .pem](#merging-private-key-and-public-certificate-in-one-pem)
  - [Merging private key and public certificate in one PKCS12 file](#merging-private-key-and-public-certificate-in-one-pkcs12-file)
  - [Convert Keys in RSA format](#convert-keys-in-rsa-format)
  - [Post-hook script](#post-hook-script)
- [Help!](#help)

<!--te-->
---

## Usage

### Image choice

#### Releases

We ship various flavors of this image as multi-arch builds: Docker (default) and Alpine. The versioning follows [SemVer](https://semver.org/). 

**Please note** that when using the `alpine` variant, using the container restart functionality won't work due to missing Docker installation and will be skipped.

| Flavor               | Tag |
|----------------------|--------------------------|
| **Docker (default)** | `latest`, `x.x.x`, `x.x`, `x` |
| **Alpine**           | `alpine`, `x.x.x-alpine`, `x.x-alpine`, `x-alpine` |

#### Edge builds

If you don't want to wait for a release or want to test new "bleeding-edge" functionalities of branch `develop`, you can use the tag `edge`.

| Flavor               | Tag |
|----------------------|--------------------------|
| **Docker (default)** | `edge`|
| **Alpine**           | `edge-alpine` |

### Environment Variables

There are some environment variables if you want to customize various things inside the Docker container:

| Variable                | Default              | Value            | Description                                                                 |
| ----------------------- | -------------------- | ---------------- | --------------------------------------------------------------------------- |
| `ACME_FILE_PATH`        | `/traefik/acme.json` | `<filepath>`     | Full file path to Traefik's certificates storage.                           |
| `DOMAIN`                | unset                | `<extension>`    | Extract only for specified domains (comma-separated list) - instead of all. |
| `OVERRIDE_UID`          | unset                | `<number>`       | Change ownership of certificate and key to given `UID`.                     |
| `OVERRIDE_GID`          | unset                | `<number>`       | Change ownership of certificate and key to given `GID`.                     |
| `COMBINE_PKCS12`        | unset                | `yes`            | If set to `yes`, an additional combined PKCS12 file is created.             |
| `PKCS12_PASSWORD`       | unset                | `<password>`     | Password for the combined PKCS12, see also `COMBINE_PKCS12`.                |
| `POST_HOOK_FILE_PATH`   | `/hook/hook.sh`      | `<filepath>`     | Full file path to the post hook script that should be executed after dumping process |
| `PRIVATE_KEY_FILE_NAME` | `key`                | `<filename>`     | The file name (without extension) of the generated private keys.            |
| `PRIVATE_KEY_FILE_EXT`  | `.pem`               | `<extension>`    | The file extension of the generated private keys.                           |
| `CERTIFICATE_FILE_NAME` | `cert`               | `<filename>`     | The file name (without extension) of the generated certificates.            |
| `CERTIFICATE_FILE_EXT`  | `.pem`               | `<extension>`    | The file extension of the generated certificates.                           |
| `COMBINED_PEM`          | unset                | `<filename>.pem` | The file name (with extension) of the combined PEM file (no combined certificate + key PEM file will be generated if this env var is not set!)
| `CONVERT_KEYS_TO_RSA`   | unset                | `yes`            | If set to `yes`, keys are created in RSA format also.                       |
| `RSA_KEY_FILE_NAME`     | `rsakey`             | `<filename>`     | The file name (without extension) of the generated private keys in RSA format, see also `CONVERT_KEYS_TO_RSA`. |
| `RSA_KEY_FILE_EXT`      | `.pem`               | `<extension>`    | The file extension of the generated private keys in RSA format, see also `CONVERT_KEYS_TO_RSA`. |

See below examples for usage.

### Basic setup

Mount your ACME folder into `/traefik` and output folder to `/output`. Here's an example for docker-compose:

```yaml
version: '3.7'

services:
  certdumper:
    image: ghcr.io/kereis/traefik-certs-dumper:latest
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
    image: ghcr.io/kereis/traefik-certs-dumper:latest
    volumes:
    - ./traefik/acme:/traefik:ro
    - ./output:/output:rw
    # Don't set DOMAIN
    # environment:
    # - DOMAIN=example.org
```

### Custom ACME file name

Use environment variable `ACME_FILE_PATH` if you don't want to use the default path or if your ACME JSON file has a different name.

```yaml
version: '3.7'

services:
  certdumper:
    image: ghcr.io/kereis/traefik-certs-dumper:latest
    volumes:
      - ./traefik/acme:/my/custom/path:ro
      - ./output:/output:rw
    environment:
      - ACME_FILE: /my/custom/path/acme_the_second.json
```

### Automatic container restart

If you want to have containers restarted after dumping certificates into your output folder, you can specify their names as comma-separated value and pass them through via optional parameter `-r | --restart-containers`. In this case, you must pass the Docker socket (or override `$DOCKER_HOST` if you use a Docker socket proxy). For instance:

```yaml
version: '3.7'

services:
  certdumper:
    image: ghcr.io/kereis/traefik-certs-dumper:latest
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
    image: ghcr.io/kereis/traefik-certs-dumper:latest
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
After certificate dumping, the certificates can be found in the domains' subdirectories respectively
(`/output/DOMAIN[i]/...`).

> #### ⚠️ Wildcard certificates and main domains
>
> Please note that traefik-certs-dumper dumps certificates based on their main domains. For instance, if you have a domain `example.com` and generate a wildcard domain `*.example.com`, then the certificate's main domain will most likely be `example.com`. This means, you have to use `example.com` in `DOMAIN` in order to have the wildcard certificate dumped. SANS domains will not be respected.
>
> You can also take a look at your `acme.json` file as it may give you a clue about what domains (`main`) you can specify via `DOMAIN`.

If you specify a single domain, the output folder is just `/output`.

```yaml
version: '3.7'

services:
  certdumper:
    image: ghcr.io/kereis/traefik-certs-dumper:latest
    volumes:
    - ./traefik/acme:/traefik:ro
    - ./output:/output:rw
    - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      DOMAIN: example.com,example.org,example.net,hello.example.in
```

If you leave out `DOMAIN`, then the container will dump all certificates that are available in your mounted `acme.json`.

### Health Check

This Docker image does reports its health status.
The process which monitors `run.sh` reports back `1` when it malfunctions and `0` when it is running inside Docker container.
Normally, it's embedded in the Dockerfile which means without further ado, this works out of the box. However, if you want to specify more than one health check, you can set them via `docker-compose`.

```yaml
version: '3.7'

services:
  certdumper:
    image: ghcr.io/kereis/traefik-certs-dumper:latest
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
    image: ghcr.io/kereis/traefik-certs-dumper:latest
    volumes:
    - ./traefik/acme:/traefik:ro
    - ./output:/output:rw
    - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      DOMAIN: example.com,example.org,example.net,hello.example.in
      COMBINED_PEM: my_concatted_file.pem
```

### Merging private key and public certificate in one PKCS12 file

Some applications like [Plex](https://www.plex.tv/de/) need both private key and public certificate to be concatenated to one PKCS12 file. In this case, you can set the environment variable `COMBINE_PKCS12=yes`. Each time `traefik-certs-dumper` dumps the certificates for specified `DOMAIN`, this script will create a file named `cert.p12` in each domain's folder respectively. The password can be set with the environment variable `PKCS12_PASSWORD`. If you want to use Docker Secrets instead, use the environment variable `PKCS12_PASSWORD_FILE`. Note that `PKCS12_PASSWORD` has higher priority. If none of those are set, the password will be empty.

```yaml
version: '3.7'

services:
  certdumper:
    image: ghcr.io/kereis/traefik-certs-dumper:latest
    container_name: traefik_certdumper
    network_mode: none
    volumes:
      - ./traefik/acme:/traefik:ro
      - ./output:/output:rw
      - /var/run/docker.sock:/var/run/docker.sock:ro
    secrets:
      - pkcs12_password
    environment:
      DOMAIN: example.com
      PKCS12_PASSWORD_FILE: /run/secrets/pkcs12_password
      COMBINE_PKCS12: "yes"
      OVERRIDE_UID: 1000
      OVERRIDE_GID: 1000

secrets:
  pkcs12_password:
    file: /path/to/secret/PKCS12_PASSWORD
```

### Convert keys in RSA format

Some applications like [MySQL](https://www.mysql.com/) or [mariaDB](https://mariadb.org/) need their keys in RSA format. In this case, you can set the environment variable `CONVERT_KEYS_TO_RSA`. Each time `traefik-certs-dumper` dumps the certificates, this script will create a file named `rsakey.pem` in each domain's folder respectively. If required, this file name can be configured using the environment variables `RSA_KEY_FILE_NAME` and `RSA_KEY_FILE_EXT`.

```yaml
version: '3.7'

services:
  certdumper:
    image: ghcr.io/kereis/traefik-certs-dumper:latest
    container_name: traefik_certdumper
    network_mode: none
    volumes:
      - ./traefik/acme:/traefik:ro
      - ./output:/output:rw
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      CONVERT_KEYS_TO_RSA: "yes"
      RSA_KEY_FILE_NAME: "myrsa"
      RSA_KEY_FILE_EXT: ".ext"

```

### Post-hook script

You can run a script after the dumping process. Simply create a shell script and mount it to your container (target by default: `/hook/hook.sh`). You can override the file path to the post-hook script inside the container via environment variable `POST_HOOK_FILE_PATH` if necessary.

```bash
#!/bin/bash
# Example post-hook.sh
touch /output/posthook.example
```

```yaml
# With default POST_HOOK_FILE_PATH
version: '3.7'

services:
  certdumper:
    image: ghcr.io/kereis/traefik-certs-dumper:latest
    volumes:
      - ./traefik/acme:/traefik:ro
      - ./output:/output:rw
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./hook.sh:/hook/hook.sh:ro
```

```yaml
# With custom POST_HOOK_FILE_PATH
version: '3.7'

services:
  certdumper:
    image: ghcr.io/kereis/traefik-certs-dumper:latest
    volumes:
      - ./traefik/acme:/traefik:ro
      - ./output:/output:rw
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./hook.sh:/to/my/custom/hook.sh:ro
    environment:
      POST_HOOK_FILE_PATH: "/to/my/custom/hook.sh"
```

## Help

If you need help using this image, have suggestions or want to report a problem, feel free to open an issue on GitHub!
