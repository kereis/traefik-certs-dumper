# traefik-certs-dumper

[![Docker Layers](https://images.microbadger.com/badges/image/humenius/traefik-certs-dumper.svg)](https://hub.docker.com/r/humenius/traefik-certs-dumper)
[![Docker Image Latest Version](https://images.microbadger.com/badges/version/humenius/traefik-certs-dumper:1.3.2.svg)](https://hub.docker.com/r/humenius/traefik-certs-dumper)

Dumps Let's Encrypt certificates of a specified domain to `.pem` and `.key` files which Traefik stores in `acme.json`.

This image uses:
- a bash script that derrivates from [mailu/traefik-certdumper](https://hub.docker.com/r/mailu/traefik-certdumper)
- [ldez's traefik-certs-dumper](https://github.com/ldez/traefik-certs-dumper)
Special thanks to them!

**IMPORTANT**: It's supposed to work with Traefik **v2** or higher! If you want to use this certificate dumper with **v1**, you can simply change the image to [mailu/traefik-certdumper](https://hub.docker.com/r/mailu/traefik-certdumper).

## Usage
### Basic setup
Mount your ACME folder into `/traefik` and output folder to `/output`. Here's an example for docker-compose:
```yaml
version: '3.7'

services:
  certdumper:
    image: humenius/traefik-certs-dumper:latest
    container_name: traefik_certdumper
    volumes:
    - ./traefik/acme:/traefik:ro
    - ./output:/output:rw
    environment:
    - DOMAIN=example.org
```

### Automatic container restart
If you want to have containers restarted after dumping certificates into your output folder, you can specify their names as comma-separated value and pass them through via optional parameter `-r | --restart-containers`. In this case, you must pass the Docker socket (or override `$DOCKER_HOST` if you use a Docker socket proxy). For instance:
```yaml
version: '3.7'

services:
  certdumper:
    image: humenius/traefik-certs-dumper:latest
    container_name: traefik_certdumper
    command: --restart-containers container1,container2,container3
    volumes:
    - ./traefik/acme:/traefik:ro
    - ./output:/output:rw
    - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
    - DOMAIN=example.org
```

### Change ownership of certificate and key files
If you want to change the onwership of the certificate and key files because your container runs on different permissions than `root`, you can specify the UID and GID as an environment variable. These environment variables are `OVERRIDE_UID` and `OVERRIDE_GID`. These can only be integers and must both be set for the override to work. For instance:
```yaml
version: '3.7'

services:
  certdumper:
    image: humenius/traefik-certs-dumper:latest
    container_name: traefik_certdumper
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
    container_name: traefik_certdumper
    volumes:
    - ./traefik/acme:/traefik:ro
    - ./output:/output:rw
    - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      DOMAIN: example.com,example.org,example.net,hello.example.in
```

### Health Check
This Docker image does reports its health status.
The process which monitors `run.sh` reports back `1` when it malfunctions and `0` when it is running inside docker container.
Normally, it's embedded in the Dockerfile which means without further ado, this works out of the box. However, if you want to specify more than one health check, you can set them via `docker-compose`.
```yaml
version: '3.7'

services:
  certdumper:
    image: humenius/traefik-certs-dumper:latest
    container_name: traefik_certdumper
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


## Help!
If you need help using this image, have suggestions or want to report a problem, feel free to open an issue on GitHub!
