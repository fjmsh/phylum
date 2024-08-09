CREATE TABLE storage_backends(
    name         TEXT  PRIMARY KEY,
    driver       TEXT  NOT NULL,
    params       JSONB NOT NULL
);

---- create above / drop below ----

DROP TABLE storage_backends