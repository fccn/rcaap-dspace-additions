-- ---------------
-- AUTHOR PROFILES
-- ---------------

CREATE SEQUENCE authorprofile_seq;


CREATE TABLE authorprofile
(
    authorprofile_id          INTEGER PRIMARY KEY,
    photo_bitstream_id    INTEGER REFERENCES Bitstream(bitstream_id),
    uuid             VARCHAR(50) NULL,
    last_modified   TIMESTAMP
    
);
CREATE INDEX authorprofile_photo_bitstream_fk_idx ON authorprofile(photo_bitstream_id);