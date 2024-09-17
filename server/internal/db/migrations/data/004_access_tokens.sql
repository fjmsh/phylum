CREATE TABLE access_tokens(
    id          TEXT NOT NULL PRIMARY KEY,
    created     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires     TIMESTAMP NOT NULL,
    username    TEXT NOT NULL REFERENCES users(username) ON UPDATE CASCADE ON DELETE CASCADE
);

---- create above / drop below ----

DROP TABLE access_tokens;