ALTER TABLE pending_logins ADD COLUMN loopback_port INTEGER NOT NULL DEFAULT 0;

---- create above / drop below ----

ALTER TABLE pending_logins DROP COLUMN loopback_port;