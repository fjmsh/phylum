ALTER TABLE resources ADD COLUMN permissions JSONB NOT NULL DEFAULT '{}';

ALTER TABLE resources ADD COLUMN grants JSONB NOT NULL DEFAULT '{}';

CREATE OR REPLACE FUNCTION jsonb_bitwise_or(a JSONB, b JSONB)
RETURNS JSONB LANGUAGE SQL AS $$
    SELECT
        COALESCE(jsonb_object_agg(
            COALESCE(ka, kb),
            CASE
                WHEN va ISNULL THEN vb::integer
                WHEN vb ISNULL THEN va::integer
                ELSE va::integer | vb::integer
            END
        ), '{}'::JSONB)
    FROM jsonb_each(a) e1(ka, va)
    FULL JOIN jsonb_each(b) e2(kb, vb) ON ka = kb
$$;

CREATE AGGREGATE agg_jsonb_bitwise_or(JSONB) (
    SFUNC = jsonb_bitwise_or,
    STYPE = JSONB,
    INITCOND = '{}'
);

---- create above / drop below ----
DROP AGGREGATE agg_jsonb_bitwise_or(JSONB);

DROP FUNCTION jsonb_bitwise_or;

ALTER TABLE resources DROP COLUMN permissions;

ALTER TABLE resources DROP COLUMN grants;