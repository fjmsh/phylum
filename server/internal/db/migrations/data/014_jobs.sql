
CREATE TABLE jobs(
  id            SERIAL      PRIMARY KEY,
  state         SMALLINT    NOT NULL DEFAULT 0,
  attempt       SMALLINT    NOT NULL DEFAULT 0,

  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  attempted_at  TIMESTAMPTZ,
  finalized_at  TIMESTAMPTZ,

  -- types stored out-of-band
  args          JSONB,
  errors        JSONB[],
  kind          TEXT NOT NULL,

  CONSTRAINT finalized_or_finalized_at_null CHECK ((state IN (2, 4, 5) AND finalized_at IS NOT NULL) OR finalized_at IS NULL)
);

CREATE FUNCTION notify_job_inserted() RETURNS trigger AS $$
BEGIN
    PERFORM pg_notify('job_inserted', row_to_json(NEW)::TEXT);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Do not notify for deletes. The server needs to be manually restarted in that case
CREATE TRIGGER job_inserted
    AFTER INSERT ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION notify_job_inserted();

---- create above / drop below ----

DROP TRIGGER job_inserted ON jobs;

DROP FUNCTION notify_job_inserted();
