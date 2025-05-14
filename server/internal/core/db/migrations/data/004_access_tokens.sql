CREATE TABLE access_tokens(
    id          TEXT NOT NULL PRIMARY KEY,
    created     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires     TIMESTAMP NOT NULL,
    user_id     INT NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE
);

---- create above / drop below ----

DROP TABLE access_tokens;