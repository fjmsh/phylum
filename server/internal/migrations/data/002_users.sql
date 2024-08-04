CREATE TABLE users(
    id            SERIAL PRIMARY KEY,
    username      TEXT NOT NULL UNIQUE,
    display_name  TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    deleted       TIMESTAMP
);

---- create above / drop below ----

DROP TABLE users;