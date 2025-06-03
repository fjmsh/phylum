ALTER TABLE resource_versions ADD COLUMN storage TEXT NOT NULL DEFAULT '';

---- create above / drop below ----

ALTER TABLE resource_versions DROP COLUMN storage;