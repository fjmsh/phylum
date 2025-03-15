ALTER TABLE resources ADD COLUMN permissions JSONB NOT NULL DEFAULT '{}';

ALTER TABLE resources ADD COLUMN grants JSONB NOT NULL DEFAULT '{}';

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

ALTER TABLE resources DROP COLUMN permissions;

ALTER TABLE resources DROP COLUMN grants;