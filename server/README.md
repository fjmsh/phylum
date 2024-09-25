### Setting up the test databsae

```
podman run -d \
    --name phylum \
    -e POSTGRES_USER=phylum \
    -e POSTGRES_PASSWORD=phylum \
    -e POSTGRES_DB=phylum \
    -p 5432:5432 \
    docker.io/postgres:latest
```
