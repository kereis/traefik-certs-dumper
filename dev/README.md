# Development environment setup

This directory contains a docker-compose stack which can help you during development. Instead of a tagged image, it builds a new one using the Dockerfiles in `/docker`.

A dummy `acme.json` is provided using the domain `example.com`. It contains certificates for the following domains:
- `example.com`, `www.example.com`
- `test.example.com`
- `autodiscover.example.com`, `autoconfig.example.com`, `webmail.example.com`, `email.example.com`

These certificates are self-signed and should **NEVER** be used for the actual operations other than testing and development purposes.