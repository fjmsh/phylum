ALTER TABLE resource_versions ADD COLUMN pending BOOLEAN NOT NULL DEFAULT false;

---- create above / drop below ----

ALTER TABLE resource_versions DROP COLUMN pending;