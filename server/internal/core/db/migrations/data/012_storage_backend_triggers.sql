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

---- create above / drop below ----

DROP TRIGGER backend_updates ON storage_backends;

DROP FUNCTION notify_backend_updates();
