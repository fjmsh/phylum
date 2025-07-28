ALTER TABLE resource_versions ADD COLUMN thumb BOOLEAN NOT NULL DEFAULT FALSE;

---- create above / drop below ----

ALTER TABLE resource_versions DROP COLUMN thumb;
