ALTER TABLE partial_uploads ADD COLUMN finalized_resource_id UUID REFERENCES resources(id) ON UPDATE CASCADE ON DELETE CASCADE;


---- create above / drop below ----

ALTER TABLE partial_uploads DROP COLUMN finalized_resource_id;
