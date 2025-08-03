ALTER TABLE api_keys ADD COLUMN last_used TIMESTAMPTZ;

---- create above / drop below ----

ALTER TABLE api_keys DROP COLUMN last_used_by;
