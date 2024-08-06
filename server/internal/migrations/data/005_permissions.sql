CREATE TABLE permissions(
    resource_id  uuid NOT NULL,
    user_id      INTEGER NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
    permission   INT NOT NULL DEFAULT 0,
    PRIMARY KEY(resource_id, user_id)
);

---- create above / drop below ----

DROP TABLE permissions;