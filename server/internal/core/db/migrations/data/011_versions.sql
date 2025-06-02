CREATE TABLE resource_versions(
    id              UUID        PRIMARY KEY,
    resource_id     UUID        NOT NULL REFERENCES resources(id),
    created         TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted         TIMESTAMP,
    size            BIGINT      NOT NULL,
    mime_type       TEXT        NOT NULL,
    sha256          TEXT        NOT NULL
);

ALTER TABLE resources DROP COLUMN content_length;
ALTER TABLE resources DROP COLUMN content_type;
ALTER TABLE resources DROP COLUMN content_sha256;



---- create above / drop below ----

DROP TABLE resource_versions;

ALTER TABLE resources ADD COLUMN content_length BIGINT NOT NULL DEFAULT 0;
ALTER TABLE resources ADD COLUMN content_type TEXT NOT NULL DEFAULT '';
ALTER TABLE resources ADD COLUMN content_sha256 TEXT NOT NULL DEFAULT '';

