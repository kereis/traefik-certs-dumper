# traefik-certs-dumper
Dumps Let's Encrypt certificates of a specified domain to `.pem` and `.key` files which Traefik stores in `acme.json`. 

This images derrivates from [mailu/traefik-certdumper](https://hub.docker.com/r/mailu/traefik-certdumper). Special thanks to them!

**IMPORTANT**: It's supposed to work with Traefik **v2** or higher! If you want to use this certificate dumper with **v1**, you can simply change the image to [mailu/traefik-certdumper](https://hub.docker.com/r/mailu/traefik-certdumper).

## Usage
Mount your ACME folder into `/traefik` and output folder to `/output`. Here's an example for docker-compose:
```yaml
version: '3.7'

services:
  certdumper:
    image: humenius/traefik-certs-dumper
    container_name: traefik_certdumper
    volumes:
    - ./traefik/acme:/traefik:ro
    - ./output:/output:rw
    environment:
    - DOMAIN=example.org
```

## Help!
If you need help using this image, have suggestions or want to report a problem, feel free to open an issue on GitHub!