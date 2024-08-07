CREATE TABLE users(
    id            SERIAL PRIMARY KEY,
    username      TEXT NOT NULL UNIQUE,
    created       TIMESTAMP NOT NULL,
    modified      TIMESTAMP NOT NULL,
    display_name  TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    deleted       TIMESTAMP
);

INSERT INTO users(username, created, modified, display_name, password_hash) VALUES(
    'phylum',
    NOW(),
    NOW(),
    'Phylum',
    'CANNOT_LOG_IN'
);

---- create above / drop below ----

DROP TABLE users;