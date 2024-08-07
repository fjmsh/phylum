ALTER TABLE users ADD home uuid REFERENCES resources(id) ON UPDATE CASCADE ON DELETE CASCADE;

---- create above / drop below ----

ALTER TABLE users DROP COLUMN home;