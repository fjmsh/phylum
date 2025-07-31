ALTER TABLE resource_versions ADD COLUMN preview BOOLEAN NOT NULL DEFAULT FALSE;

---- create above / drop below ----

ALTER TABLE resource_versions DROP COLUMN preview;
