CREATE TABLE bookmarks(
    user_id         INT         NOT NULL REFERENCES users(id),
    resource_id     UUID        NOT NULL REFERENCES resources(id),
    name            TEXT        NOT NULL,
    dir             BOOLEAN     NOT NULL,
    created         TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted         TIMESTAMPTZ,
    PRIMARY KEY(user_id, resource_id)
);

CREATE INDEX modified_bookmarks ON bookmarks(user_id, modified);

---- create above / drop below ----

DROP INDEX modified_bookmarks;

DROP TABLE bookmarks;