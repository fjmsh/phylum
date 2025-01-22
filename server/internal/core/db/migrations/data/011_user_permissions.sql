ALTER TABLE users ADD COLUMN permissions INTEGER NOT NULL DEFAULT 0;

---- create above / drop below ----

ALTER TABLE users DROP COLUMN permissions;