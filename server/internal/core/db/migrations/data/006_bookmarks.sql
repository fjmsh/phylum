CREATE TABLE bookmarks(
    username        TEXT        NOT NULL REFERENCES users(username),
    resource_id     UUID        NOT NULL REFERENCES resources(id),
    name            TEXT        NOT NULL,
    dir             BOOLEAN     NOT NULL,
    created         TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified        TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted         TIMESTAMP,
    PRIMARY KEY(username, resource_id)
);

CREATE INDEX modified_bookmarks ON bookmarks(username, modified);

---- create above / drop below ----

DROP INDEX modified_bookmarks;

DROP TABLE bookmarks;