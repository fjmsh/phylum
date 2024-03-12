CREATE TABLE users(
    id SERIAL,
    display_name TEXT NOT NULL,
    username TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    deleted TIMESTAMP
);

CREATE UNIQUE INDEX unique_username ON users(username) WHERE deleted IS NULL;