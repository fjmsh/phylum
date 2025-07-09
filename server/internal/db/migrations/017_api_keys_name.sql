ALTER TABLE api_keys ADD COLUMN name TEXT;

CREATE UNIQUE INDEX unique_named_user_key ON api_keys(user_id, name);

---- create above / drop below ----

DROP INDEX unique_named_user_key;

ALTER TABLE api_keys DROP COLUMN name;
