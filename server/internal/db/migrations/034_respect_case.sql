ALTER TABLE publinks ALTER COLUMN id SET DATA TYPE TEXT;

ALTER TABLE resources ALTER COLUMN name SET DATA TYPE TEXT;

DROP COLLATION case_insensitive;

---- create above / drop below ----

CREATE COLLATION case_insensitive (provider = icu, locale = 'und-u-ks-level2', deterministic = false);

ALTER TABLE resources ALTER COLUMN name SET DATA TYPE TEXT COLLATE case_insensitive;

ALTER TABLE publinks ALTER COLUMN id SET DATA TYPE TEXT COLLATE case_insensitive;
