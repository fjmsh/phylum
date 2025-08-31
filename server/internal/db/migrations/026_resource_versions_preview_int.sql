ALTER TABLE resource_versions DROP COLUMN preview;

ALTER TABLE resource_versions ADD COLUMN imgres INTEGER NOT NULL DEFAULT 0;


---- create above / drop below ----

ALTER TABLE resource_versions DROP COLUMN imgres;

ALTER TABLE resource_versions ADD COLUMN preview BOOLEAN NOT NULL DEFAULT FALSE;
