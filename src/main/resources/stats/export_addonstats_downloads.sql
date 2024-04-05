-- execute via:
--      psql -d dspace -f export-file.sql
-- it will result in a csv file in /tmp directory

CREATE OR REPLACE FUNCTION stats.uuid_generate_rcaap()
RETURNS UUID AS $$
DECLARE
    random_text TEXT;
    result UUID;
BEGIN
    random_text := md5(random()::text || ':' || random()::text);

    -- Coloca '4' na posição 13
    random_text := overlay(random_text placing '4' from 13);

    -- Coloca o hexadecimal aleatório na posição 17
    random_text := overlay(random_text placing to_hex(floor(random()*(11-8+1) + 8)::int)::text from 17);

    -- Converte para UUID
    result := uuid_in(random_text::cstring);

    RETURN result;
END;
$$ LANGUAGE plpgsql;


-- CREATE VIEW "v_bitbundlename" --------------------------------
CREATE OR REPLACE VIEW "stats"."v_bitbundlename" AS SELECT b.bitstream_id as "bitstream_id", mdv.text_value as "bundle_name"
FROM bitstream b
left join bundle2bitstream b2b ON b2b.bitstream_id = b.bitstream_id
left join metadatavalue mdv ON mdv.resource_id = b2b.bundle_id AND mdv.resource_type_id = 1
WHERE metadata_field_id IN (SELECT metadata_field_id from metadatafieldregistry where metadata_schema_id=(SELECT metadata_schema_id from metadataschemaregistry where short_id='dc') and element = 'title' and qualifier is null);-- -------------------------------------------------------------;

-- Generate CSV file
COPY (

SELECT
  stats.uuid_generate_rcaap() as "uid",
--  "workflowItemId",
--  d.download_id as "_version_",
  'DSpace 5.X - UMinho addon statistics stored data' as "userAgent",
--  d.user_id as "submitter",  -- "anonymous"
--  "dns",
  'false' as  "isBot",
  REPLACE(d.country_code, '--', '' ) as "countryCode",
  coll.owning_collection as "owningColl",
--  "actor",
  '0' as "type",
  comm.community_id as  "owningComm",
  'view' as "statistics_type",
  d.ip as "ip",
--  "city",
  d.bitstream_id as "id",
--  "previousWorkflowStep",
--  "referrer",
  TO_CHAR(TO_TIMESTAMP(d.date || ' ' || d.time, 'YYYY-MM-DD HH24:MI:SS:MS'),'YYYY-MM-DD') || 'T' || TO_CHAR(TO_TIMESTAMP(d.date || ' ' || d.time, 'YYYY-MM-DD HH24:MI:SS:MS'),'HH24:MI:SS.MS') || 'Z' as "time",
  d.item_id as "owningItem",
--  "continent",
--  "longitude",
--  "latitude",
  (SELECT v_bitbundlename.bundle_name FROM stats.v_bitbundlename WHERE v_bitbundlename.bitstream_id = d.bitstream_id) as "bundleName"
--  "epersonid",
--  "workflowStep"

FROM stats.download as d
LEFT JOIN item as "coll" on d.item_id = coll.item_id
LEFT JOIN community2collection as "comm" on coll.owning_collection = comm.collection_id

WHERE d.date BETWEEN '2009-12-01'::date AND ('2009-12-01'::date + interval '1 month - 1 day')

) TO '/tmp/statistics_export_downloads_2009-12.csv' 
  DELIMITER ',' CSV HEADER
;