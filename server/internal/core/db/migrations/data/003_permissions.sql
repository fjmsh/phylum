CREATE TABLE permissions(
    resource_id     UUID        NOT NULL REFERENCES resources(id),
    username        TEXT        NOT NULL REFERENCES users(username),
    modified        TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    value           INT
);

CREATE INDEX shared_resources ON permissions(username, modified DESC);

---- create above / drop below ----

DROP INDEX shared_resources;

DROP TABLE permissions;