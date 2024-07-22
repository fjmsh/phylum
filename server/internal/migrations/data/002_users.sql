CREATE TABLE users(
    username      TEXT NOT NULL PRIMARY KEY,
    display_name  TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    deleted       TIMESTAMP
);

---- create above / drop below ----

DROP TABLE users;