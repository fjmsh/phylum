CREATE TABLE libraries(
    id           uuid   PRIMARY KEY,
    owner        SERIAL NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
    display_name TEXT   NOT NULL,
    deleted      TIMESTAMP,
    storage_backend TEXT NOT NULL REFERENCES storage_backends(name) ON UPDATE CASCADE ON DELETE CASCADE
);
