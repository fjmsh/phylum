CREATE TABLE permissions(
    resource_id  uuid NOT NULL,
    username     TEXT NOT NULL,
    permission   INT NOT NULL,
    PRIMARY KEY(resource_id, username)
);

---- create above / drop below ----

DROP TABLE permissions;