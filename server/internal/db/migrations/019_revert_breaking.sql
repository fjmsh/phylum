ALTER TABLE pending_logins SET LOGGED;
ALTER TABLE pending_logins DROP COLUMN created_at;
ALTER TABLE pending_logins ADD COLUMN expires TIMESTAMPTZ;


---- create above / drop below ----

ALTER TABLE pending_logins DROP COLUMN expires;
ALTER TABLE pending_logins ADD COLUMN created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE pending_logins SET UNLOGGED;