ALTER TABLE pending_logins ADD COLUMN code_verifier VARCHAR(128) NOT NULL DEFAULT '';

---- create above / drop below ----

ALTER TABLE pending_logins DROP COLUMN code_verifier;
