CREATE TABLE reset_tokens(
    user_id     INT PRIMARY KEY REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
    token       TEXT NOT NULL,
    expires     TIMESTAMP NOT NULL
);


---- create above / drop below ----

DROP TABLE reset_tokens;