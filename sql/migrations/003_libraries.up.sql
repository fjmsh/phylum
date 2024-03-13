CREATE TABLE libraries(
    id           uuid   PRIMARY KEY,
    owner        SERIAL NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
    display_name TEXT   NOT NULL,
    deleted      TIMESTAMP
);
