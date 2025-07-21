## Phylum Server

The Phylum server is written in Go, and requires a postgres server to be running.

```
$ docker run -it \
    -e POSTGRES_USER=phylum \
    -e POSTGRES_PASSWORD=<password> \
    -v ./data/postgres:/var/lib/postgresql/data \
    docker.io/postgres:17
```

The working directory can be changed by passing in the `-W` flag, which is useful for local development. The `data` folder in the repo root is intended to be the working directory for local development, and is ignored by git.

Add your db password to `data/config.yml`, and run the server:
```
$ go run -C server cmd/phylum.go -W ../data serve
```

To use the CLI, you can use:
```
$ go run -C server cmd/phylum.go -W ../data <cmd>
```

### API
An OpenAPI document is a work in progress. If you do intend to look around, note that almost all `<path>`s can have a `<uuid>:` prefix to make the path relative to that UUID. This also means that if you know the UUID of the resource, you can simply use `<uuid>:` as the path. This is the recommended way, and is the way the client app uses the API.

