CREATE TABLE storage_mounts(
    id      UUID    PRIMARY KEY REFERENCES resources ON DELETE CASCADE,
    storage TEXT    NOT NULL REFERENCES storage_backends(name) ON UPDATE CASCADE ON DELETE CASCADE
);

---- create above / drop below ----

DROP TABLE storage_mounts;
