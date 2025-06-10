CREATE TABLE resources (
  id              uuid      PRIMARY KEY,
  name            TEXT      NOT NULL,
  parent          uuid      REFERENCES resources(id) ON UPDATE CASCADE ON DELETE CASCADE,
  dir             BOOLEAN   NOT NULL,
  created         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  modified        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted         TIMESTAMP,
  permissions     JSONB     NOT NULL DEFAULT '{}',
  grants          JSONB     NOT NULL DEFAULT '{}'
);

CREATE TABLE resource_versions(
    id              UUID        PRIMARY KEY,
    resource_id     UUID        NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    created         TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted         TIMESTAMP,
    size            BIGINT      NOT NULL,
    mime_type       TEXT        NOT NULL,
    sha256          TEXT        NOT NULL
);

CREATE UNIQUE INDEX unique_member_resource_name ON resources(parent, name) WHERE deleted IS NULL;

CREATE INDEX versions_by_resource ON resource_versions(resource_id, created DESC);

CREATE OR REPLACE FUNCTION phylum_merge_permission_grants(a JSONB, b JSONB)
RETURNS JSONB LANGUAGE SQL AS $$
    SELECT 
        COALESCE(jsonb_object_agg(
            COALESCE(ka, kb), 
            CASE
                WHEN vb ISNULL THEN va::integer 
                WHEN va ISNULL THEN (vb -> 'p')::integer 
                ELSE va::integer | (vb -> 'p')::integer 
            END
        ), '{}'::JSONB)
    FROM jsonb_each(a) e1(ka, va)
    FULL JOIN jsonb_each(b) e2(kb, vb) ON ka = kb
$$;

---- create above / drop below ----

DROP FUNCTION phylum_merge_permission_grants;

DROP INDEX unique_member_resource_name;

DROP INDEX versions_by_resource;

DROP TABLE resource_versions;

DROP TABLE resources;
