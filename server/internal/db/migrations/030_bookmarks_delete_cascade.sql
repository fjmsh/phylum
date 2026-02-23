ALTER TABLE bookmarks
    DROP CONSTRAINT bookmarks_user_id_fkey,
    ADD CONSTRAINT bookmarks_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,
    DROP CONSTRAINT bookmarks_resource_id_fkey,
    ADD CONSTRAINT bookmarks_resource_id_fkey
        FOREIGN KEY (resource_id)
        REFERENCES resources(id)
        ON DELETE CASCADE;

---- create above / drop below ----

ALTER TABLE bookmarks
    DROP CONSTRAINT bookmarks_user_id_fkey,
    ADD CONSTRAINT bookmarks_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES users(id),
    DROP CONSTRAINT bookmarks_resource_id_fkey,
    ADD CONSTRAINT bookmarks_resource_id_fkey
        FOREIGN KEY (resource_id)
        REFERENCES resources(id);