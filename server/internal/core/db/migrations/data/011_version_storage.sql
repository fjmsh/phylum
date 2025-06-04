ALTER TABLE resource_versions ADD COLUMN storage TEXT NOT NULL;

---- create above / drop below ----

ALTER TABLE resource_versions DROP COLUMN storage;