CREATE EXTENSION unaccent;
CREATE EXTENSION pg_trgm;

CREATE OR REPLACE FUNCTION public.immutable_unaccent(regdictionary, text)
  RETURNS text
  LANGUAGE c IMMUTABLE PARALLEL SAFE STRICT AS
'$libdir/unaccent', 'unaccent_dict';

CREATE OR REPLACE FUNCTION public.f_prepare_search(text)
  RETURNS text
  LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT
RETURN lower(public.immutable_unaccent(regdictionary 'public.unaccent', $1));

CREATE INDEX resource_name_search ON resources USING GIN (f_prepare_search(name) gin_trgm_ops);

---- create above / drop below ----

DROP FUNCTION public.f_prepare_search

DROP FUNCTION public.immutable_unaccent;

DROP EXTENSION pg_trgm;

DROP EXTENSION unaccent;