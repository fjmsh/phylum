ALTER TABLE api_keys ALTER COLUMN expires DROP NOT NULL;

---- create above / drop below ----

ALTER TABLE api_keys ALTER COLUMN expires SET NOT NULL;
