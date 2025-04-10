CREATE TABLE trash(
    id UUID PRIMARY KEY REFERENCES resources ON DELETE CASCADE
);

---- create above / drop below ----

DROP TABLE trash;