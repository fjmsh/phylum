ALTER TABLE users DROP COLUMN permissions;

ALTER TABLE users ADD COLUMN permissions TEXT[];


---- create above / drop below ----

ALTER TABLE users DROP COLUMN permissions;

ALTER TABLE users ADD COLUMN permissions INTEGER NOT NULL DEFAULT 0;
