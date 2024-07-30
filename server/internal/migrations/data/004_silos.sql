CREATE TABLE silos(
    id       UUID   PRIMARY KEY,
    created  TIMESTAMP NOT NULL,
    modified TIMESTAMP NOT NULL,
    deleted  TIMESTAMP,
    owner    TEXT NOT NULL REFERENCES users(username) ON UPDATE CASCADE ON DELETE CASCADE,
    name     TEXT   NOT NULL,
    storage  TEXT NOT NULL REFERENCES storage_backends(name) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE UNIQUE INDEX silo_by_name ON silos(name);

---- create above / drop below ----

DROP INDEX silo_by_name;

DROP TABLE silos;
