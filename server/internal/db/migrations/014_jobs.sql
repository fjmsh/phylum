CREATE TABLE jobs(
  id            SERIAL      PRIMARY KEY,
  status        SMALLINT    NOT NULL DEFAULT 0,
  attempts       SMALLINT    NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  scheduled_at  TIMESTAMPTZ,

  -- types stored out-of-band
  kind          TEXT NOT NULL,
  args          JSONB,
  errors        JSONB[]
);

CREATE TABLE job_sequences(
  job_id        INTEGER REFERENCES jobs(id) ON DELETE CASCADE,
  sequence      TEXT NOT NULL,
  PRIMARY KEY(job_id, sequence)
);

CREATE TABLE job_dependencies(
  job_id        INTEGER REFERENCES jobs(id) ON DELETE CASCADE,
  dependency    INTEGER REFERENCES jobs(id) ON DELETE CASCADE,
  PRIMARY KEY(job_id, dependency)
);


CREATE INDEX next_available_job ON jobs(id) WHERE (status = 0 OR status = 2);

CREATE INDEX scheduled_jobs ON jobs(scheduled_at);

CREATE INDEX job_sequences_by_sequence ON job_sequences(sequence);

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

DROP INDEX job_sequences_by_sequence;

DROP INDEX next_available_job;

DROP INDEX scheduled_jobs;

DROP TABLE job_sequences;

DROP TABLE job_dependencies;

DROP TABLE jobs;
