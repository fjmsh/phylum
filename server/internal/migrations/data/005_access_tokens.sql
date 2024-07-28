CREATE TABLE access_tokens(
    id          TEXT NOT NULL PRIMARY KEY,
    created     TIMESTAMP NOT NULL,
    expires     TIMESTAMP NOT NULL,
    username    TEXT NOT NULL
);

---- create above / drop below ----

DROP TABLE access_tokens;