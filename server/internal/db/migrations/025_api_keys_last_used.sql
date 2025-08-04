ALTER TABLE api_keys ADD COLUMN last_used TEXT;

---- create above / drop below ----

ALTER TABLE api_keys DROP COLUMN last_used;
