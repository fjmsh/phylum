ALTER TABLE api_keys ADD COLUMN scopes TEXT[] NOT NULL DEFAULT '{"*"}';

---- create above / drop below ----

ALTER TABLE api_keys DROP COLUMN scopes;
