CREATE TABLE users(
    id            SERIAL PRIMARY KEY,
    email      TEXT NOT NULL UNIQUE,
    created       TIMESTAMP NOT NULL,
    modified      TIMESTAMP NOT NULL,
    display_name  TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    deleted       TIMESTAMP,
    root          uuid NOT NULL REFERENCES resources(id),
    home          uuid NOT NULL REFERENCES resources(id)
);

---- create above / drop below ----

DROP TABLE users;