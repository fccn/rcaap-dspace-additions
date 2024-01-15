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
  w.item_id as  "workflowItemId",
--  w.workflow_id as "_version_",
  'DSpace 5.X - UMinho addon statistics stored data' as "userAgent",
  person.eperson_id as "submitter",
--  "dns",
  'false' as  "isBot",
-- "countryCode",
  w.collection_id as "owningColl",
  person.eperson_id as "actor",
  2 as "type",
  comm.community_id as  "owningComm",
  'workflow' as "statistics_type",
  w.ip as "ip",
--  "city",
  w.workflow_item_id as "id",
  CASE
       WHEN w.old_state = 0 THEN 'SUBMIT'
       WHEN w.old_state = 1 THEN 'STEP1POOL'
       WHEN w.old_state = 2 THEN 'STEP1'
       WHEN w.old_state = 3 THEN 'STEP2POOL'
       WHEN w.old_state = 4 THEN 'STEP2'
       WHEN w.old_state = 5 THEN 'STEP3POOL'
       WHEN w.old_state = 6 THEN 'STEP3'
       WHEN w.old_state = 7 THEN 'ARCHIVE'
       WHEN w.old_state = 10 THEN 'BATCH'
       WHEN w.old_state = 20 THEN 'SWORD'
  END as "previousWorkflowStep",
--  "referrer",
  TO_CHAR(TO_TIMESTAMP(w.date || ' ' || w.time, 'YYYY-MM-DD HH24:MI:SS:MS'),'YYYY-MM-DD') || 'T' || TO_CHAR(TO_TIMESTAMP(w.date || ' ' || w.time, 'YYYY-MM-DD HH24:MI:SS:MS'),'HH24:MI:SS.MS') || 'Z' as "time",
--  "owningItem",
--  "continent",
--  "longitude",
--  "latitude",
--  "bundleName",
--  "epersonid",
  CASE
       WHEN w.old_state = 0 THEN 'STEP1POOL'
       WHEN w.old_state = 1 THEN 'STEP1'
       WHEN w.old_state = 2 THEN 'STEP2POOL'
       WHEN w.old_state = 3 THEN 'STEP2'
       WHEN w.old_state = 4 THEN 'STEP3POOL'
       WHEN w.old_state = 5 THEN 'STEP3'
       WHEN w.old_state = 6 THEN 'ARCHIVE'
       WHEN w.old_state = 7 THEN 'ARCHIVE'
       WHEN w.old_state = 10 THEN 'ARCHIVE'
       WHEN w.old_state = 20 THEN 'ARCHIVE'
  END as "workflowStep"

FROM stats.workflow as w
LEFT JOIN eperson as "person" on w.user_id = person.email
-- LEFT JOIN community2item as "comm" on w.item_id = comm.item_id
LEFT JOIN community2collection as "comm" on w.collection_id = comm.collection_id

WHERE w.date BETWEEN '2009-12-01'::date AND ('2009-12-01'::date + interval '1 month - 1 day')

) TO '/tmp/statistics_export_workflow_2009-12.csv' 
  DELIMITER ',' CSV HEADER
;