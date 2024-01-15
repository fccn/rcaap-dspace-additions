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

-- Generate CSV file
COPY (

SELECT
  stats.uuid_generate_rcaap() as "uid",
--  "workflowItemId",
--  v.view_id as "_version_",
  'DSpace 5.X - UMinho addon statistics stored data' as "userAgent",
--  v.user_id as "submitter",  -- "anonymous"
--  "dns",
  'false' as  "isBot",
  REPLACE(v.country_code, '--', '' ) as "countryCode",
  coll.owning_collection as "owningColl",
--  "actor",
  2 as "type",
  comm.community_id as  "owningComm",
  'view' as "statistics_type",
  v.ip as "ip",
--  "city",
  v.item_id as "id",
--  "previousWorkflowStep",
--  "referrer",
  TO_CHAR(TO_TIMESTAMP(v.date || ' ' || v.time, 'YYYY-MM-DD HH24:MI:SS:MS'),'YYYY-MM-DD') || 'T' || TO_CHAR(TO_TIMESTAMP(v.date || ' ' || v.time, 'YYYY-MM-DD HH24:MI:SS:MS'),'HH24:MI:SS.MS') || 'Z' as "time"
--  "owningItem",
--  "continent",
--  "longitude",
--  "latitude",
--  "bundleName",
--  "epersonid",
--  "workflowStep"

FROM stats.view as v
LEFT JOIN item as "coll" on v.item_id = coll.item_id
LEFT JOIN community2collection as "comm" on coll.owning_collection = comm.collection_id

WHERE v.date BETWEEN '2009-12-01'::date AND ('2009-12-01'::date + interval '1 month - 1 day')

) TO '/tmp/statistics_export_views_2009-12.csv' 
  DELIMITER ',' CSV HEADER
;