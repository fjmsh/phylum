CREATE TABLE permissions(
    resource_id  uuid NOT NULL,
    user_id      INTEGER NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
    permission   INT NOT NULL,
    PRIMARY KEY(resource_id, user_id)
);

INSERT INTO permissions (
    SELECT '00000000-0000-0000-0000-000000000000', id, 511 FROM users WHERE username = 'root'
)

---- create above / drop below ----

DROP TABLE permissions;