# Custom CA Certificate

## Setup

1. Place certificate file:
```bash
cp /path/to/cert.crt custom_ca.crt
```

2. Build with certificate:
```bash
DOCKER_BUILDKIT=1 docker compose -f docker-compose.yml -f docker-compose-dev.yml build \
  --secret id=custom_ca,src=./custom_ca.crt
```

3. Build without certificate:
```bash
DOCKER_BUILDKIT=1 docker compose -f docker-compose.yml -f docker-compose-dev.yml build
```

## Client Build

```bash
DOCKER_BUILDKIT=1 docker build \
  --secret id=custom_ca,src=./custom_ca.crt \
  --build-arg HOST_DS=http://server:8080/ \
  --build-arg HOST_ST=ws://server:8081/ \
  --build-arg MLW=l \
  -f client.Dockerfile \
  --output build \
  .
```
