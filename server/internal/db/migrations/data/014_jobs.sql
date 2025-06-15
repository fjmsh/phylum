CREATE TABLE jobs(
  id            SERIAL      PRIMARY KEY,
  status        SMALLINT    NOT NULL DEFAULT 0,
  attempt       SMALLINT    NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  scheduled_at  TIMESTAMPTZ,
  attempted_at  TIMESTAMPTZ,

  -- types stored out-of-band
  kind          TEXT NOT NULL,
  args          JSONB,
  errors        JSONB[]
);

CREATE INDEX next_available_job ON jobs(id) WHERE status = 0;

CREATE INDEX scheduled_jobs ON jobs(scheduled_at);

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

DROP INDEX next_available_job;

DROP INDEX scheduled_jobs;

DROP TRIGGER job_inserted ON jobs;

DROP FUNCTION notify_job_inserted();

DROP TABLE jobs
