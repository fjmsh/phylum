DROP TABLE storage_mounts;

DROP TRIGGER backend_updates ON storage_backends;

DROP FUNCTION notify_backend_updates();

DROP TABLE storage_backends;

---- create above / drop below ----

CREATE TABLE storage_backends(
    name         TEXT  PRIMARY KEY,
    driver       TEXT  NOT NULL,
    params       JSONB NOT NULL
);

CREATE FUNCTION notify_backend_updates() RETURNS trigger AS $$
BEGIN
    PERFORM pg_notify('backend_updates', row_to_json(NEW)::TEXT);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Do not notify for deletes. The server needs to be manually restarted in that case
CREATE TRIGGER backend_updates
    AFTER INSERT OR UPDATE ON storage_backends
    FOR EACH ROW
    EXECUTE FUNCTION notify_backend_updates();

CREATE TABLE storage_mounts(
    id      UUID    PRIMARY KEY REFERENCES resources ON DELETE CASCADE,
    storage TEXT    NOT NULL REFERENCES storage_backends(name) ON UPDATE CASCADE ON DELETE CASCADE
);
