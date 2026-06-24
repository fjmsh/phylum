ALTER TABLE users DROP COLUMN permissions;

ALTER TABLE users ADD COLUMN permissions TEXT[];

UPDATE users SET permissions = '{"*"}'
    WHERE id = (SELECT id FROM users ORDER BY id ASC LIMIT 1);


---- create above / drop below ----

ALTER TABLE users DROP COLUMN permissions;

ALTER TABLE users ADD COLUMN permissions INTEGER NOT NULL DEFAULT 0;

UPDATE users SET permissions = -1
    WHERE id = (SELECT id FROM users ORDER BY id ASC LIMIT 1);
