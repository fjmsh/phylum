CREATE TABLE users(
    id            SERIAL PRIMARY KEY,
    username      TEXT NOT NULL UNIQUE,
    display_name  TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    deleted       TIMESTAMP
);

INSERT INTO users(username, display_name, password_hash) VALUES(
    'root',
    'Admin',
    'CANNOT_LOG_IN'
);

---- create above / drop below ----

DROP TABLE users;