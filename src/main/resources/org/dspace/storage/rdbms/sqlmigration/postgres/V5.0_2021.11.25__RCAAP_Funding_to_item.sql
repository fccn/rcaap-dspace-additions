-- . Adicionar o suporte do campo "relation.isProjectOfPublication" schema e "relation.isFundingAgencyOfProject"
-- . Adicionar o suporte do campo "dspace.entity.type" schema: dspace http://dspace.org/dspace
-- . Iremos ignorar os bitstreams do authorprofile
-- Para cada registo de authorprofile
-- . adicionar um nova metadata "dspace.entity.type = Person"
-- . adicionar um nova metadata "rcaap.relationship = b3df4247-d627-422a-802f-f4ab1aebf7c6", em que o "b3df4247-d627-422a-802f-f4ab1aebf7c6" é 
-- . criar uma entrada na tabela item
--    . E com o novo item id atualizar os metadatavalues resource_id (atualizar também o resource_type_id para 2 - item). Desta maneira já temos um item para cada authorprofile
--    . Eliminar o authorprofile


-- 

BEGIN;

-- Criar schema para relacoes "relation.isProjectOfPublication" e "relation.isFundingAgencyOfProject"

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'relation'), 'isProjectOfPublication');

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'relation'), 'isPublicationOfProject');

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'relation'), 'isProjectOfFundingAgency');

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'relation'), 'isFundingAgencyOfProject');

COMMIT;


BEGIN;
-- -------------------------------------------------------------
INSERT INTO "metadataschemaregistry" ( "metadata_schema_id", "namespace", "short_id") 
VALUES (nextval('metadataschemaregistry_seq'), 'https://schema.org/Project', 'project' );


INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'oaire'), 'awardNumber');

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'oaire'), 'awardTitle');

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'oaire'), 'awardURI');

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'oaire'), 'fundingStream' );

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element", "qualifier") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'project'), 'funder', 'name' );

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element", "qualifier") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'project'), 'funder', 'identifier' );


COMMIT;




BEGIN;

-- #### COLLECTION ######
-- criar coleção para projetos

INSERT INTO "collection" ( "collection_id", "submitter") 
VALUES ( nextval('collection_seq'), (select eperson_id from eperson where eperson.email = 'rcaap@sdum.uminho.pt') );

-- Criar metadatos da colecção
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, text_lang, place)
values ( currval('collection_seq'), 3,
(select metadata_field_id from metadatafieldregistry where metadata_schema_id=(select metadata_schema_id from metadataschemaregistry where short_id='dc') and element = 'title' and qualifier is null),
'Projetos', null, 0);
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, text_lang, place)
values ( currval('collection_seq'), 3,
(select metadata_field_id from "metadatafieldregistry" WHERE metadata_schema_id = (SELECT metadata_schema_id FROM metadataschemaregistry WHERE "short_id" = 'dspace') and element = 'entity' and qualifier = 'type'),
'Project', null, 0);
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, text_lang, place)
values ( currval('collection_seq'), 3,
(select metadata_field_id from "metadatafieldregistry" WHERE metadata_schema_id = (SELECT metadata_schema_id FROM metadataschemaregistry WHERE "short_id" = 'dc') and element = 'description' and qualifier = 'provenance'),
'Funding Collection created by RCAAP for DS7 migration at ' || NOW()::timestamp, null, 0);


-- relação coleção-comunidade
INSERT INTO "community2collection" ( "id", "community_id", "collection_id") 
VALUES ( 
  nextval('community2collection_seq'), 
  ( SELECT resource_id from metadatavalue 
    WHERE metadata_field_id IN (select metadata_field_id from metadatafieldregistry where metadata_schema_id=(select metadata_schema_id from metadataschemaregistry where short_id='dc') and element = 'description' and qualifier = 'provenance') 
	AND text_value LIKE 'Community created by RCAAP for entities migration%'), 
  currval('collection_seq') );

-- action_id = 0 is READ
INSERT INTO "resourcepolicy" ( "policy_id", "resource_type_id", "resource_id", "action_id", "epersongroup_id") 
VALUES ( nextval('resourcepolicy_seq'), 3, currval('collection_seq'), 0, 0 );
-- action_id = 10 is DEFAULT ITEM READ
INSERT INTO "resourcepolicy" ( "policy_id", "resource_type_id", "resource_id", "action_id", "epersongroup_id") 
VALUES ( nextval('resourcepolicy_seq'), 3, currval('collection_seq'), 10, 0 );
-- action_id = 9 is DEFAULT BITSTREAM READ
INSERT INTO "resourcepolicy" ( "policy_id", "resource_type_id", "resource_id", "action_id", "epersongroup_id") 
VALUES ( nextval('resourcepolicy_seq'), 3, currval('collection_seq'), 9, 0 );

-- CRIAR HANDLE
INSERT INTO "handle" ( "handle_id", "handle", "resource_type_id", "resource_id") 
VALUES ( nextval('handle_seq'), (select substring(handle from 0 for position('/' in handle)) from handle order by handle_id DESC limit 1) || '/' || currval('handle_seq'), 3, currval('collection_seq') );

-- #### ITEM ######

-- CREATE temporary table

CREATE TEMPORARY TABLE temp_funding(
   "item_id" Integer NOT NULL,
   "uri" VARCHAR NOT NULL, 
   "funder" VARCHAR, 
   "funder_name" VARCHAR,
   "funder_identifier" VARCHAR,
   "fundingprogramme" VARCHAR, 
   "projectid" VARCHAR, 
   "jurisdiction" VARCHAR
);

INSERT INTO "temp_funding" ( "item_id", "uri", "funder", "funder_name" , "fundingprogramme", "projectid", "jurisdiction") 
SELECT 
  nextval('item_seq') as item_id,
  text_value as uri, 
  split_part(text_value, '/', 3) AS funder, 
  split_part(text_value, '/', 3) AS funder_name,
  REPLACE(split_part(text_value, '/', 4),'%2F','/') AS fundingprogramme, 
  REPLACE(split_part(text_value, '/', 5),'%2F','/') AS projectid, 
  split_part(text_value, '/', 6) AS jurisdiction  
FROM metadatavalue 
WHERE text_value LIKE 'info:eu-repo/grantAgreement%'
AND metadata_field_id IN (select metadata_field_id from metadatafieldregistry where metadata_schema_id=(select metadata_schema_id from metadataschemaregistry where short_id='dc') and element = 'relation' and qualifier IS NULL) 
GROUP BY text_value
ORDER BY uri;

-- Update funder's name and URI
UPDATE "temp_funding" SET funder_name = 'Fundação para a Ciência e a Tecnologia', funder_identifier = 'http://doi.org/10.13039/501100001871' 
WHERE funder = 'FCT';

UPDATE "temp_funding" SET funder_name = 'Welcome Trust', funder_identifier = 'http://doi.org/10.13039/100010269' 
WHERE funder = 'WT';

UPDATE "temp_funding" SET funder_name = 'European Commission', funder_identifier = 'http://doi.org/10.13039/501100008530' 
WHERE funder = 'EC';


-- Create item table
-- criar item_id
INSERT INTO "item" ( "item_id", "submitter_id", "in_archive" , "withdrawn", "last_modified", "owning_collection", "discoverable") 
SELECT
	item_id,
	(SELECT eperson_id FROM eperson WHERE eperson.email = 'rcaap@sdum.uminho.pt') as "submitter_id",
	TRUE as "in_archive",
	FALSE as "withdrawn",
	NOW() as "last_modified",
	currval('collection_seq') as "owning_collection",
	TRUE as "discoverable"
FROM temp_funding;


INSERT INTO "resourcepolicy" ( "policy_id", "resource_type_id", "resource_id", "action_id", "epersongroup_id") 
SELECT
	nextval('resourcepolicy_seq') as "policy_id",
	2 as "resource_type_id",
	item_id as "resource_id",
	0 as "action_id",
	0 as "epersongroup_id"
FROM temp_funding;

INSERT INTO "collection2item" ( "id", "collection_id", "item_id") 
SELECT
	nextval('collection2item_seq') as "id",
	currval('collection_seq') as "collection_id",
	item_id as "item_id"
FROM temp_funding;

-- CRIAR HANDLE
INSERT INTO "handle" ( "handle_id", "handle", "resource_type_id", "resource_id")
SELECT
	nextval('handle_seq') as "handle_id",
	(select substring(handle from 0 for position('/' in handle)) from handle order by handle_id DESC limit 1) || '/' || currval('handle_seq') as "handle",
	2 as "resource_type_id",
	item_id as "resource_id"
FROM temp_funding;


-- ###  METADATA  ###

-- Create dspace.entity.type = Project for every funding
INSERT INTO "metadatavalue" ( resource_id, metadata_field_id, text_value, resource_type_id, place) 
SELECT
	item_id as "resource_id",
	(select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM metadataschemaregistry as mr WHERE "short_id" = 'dspace') and metadatafieldregistry.element = 'entity' and metadatafieldregistry.qualifier = 'type') as "metadata_field_id",
	'Project' as "text_value",
	2 as "resource_type_id",
	1 as "place"
FROM temp_funding;

-- Add metadatavalues dc.title
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, place)
SELECT
  item_id as "resource_id",
  2 as "resource_type_id",
  (select metadata_field_id from "metadatafieldregistry" WHERE metadata_schema_id = (SELECT metadata_schema_id FROM metadataschemaregistry WHERE "short_id" = 'dc') and element = 'title' and qualifier IS NULL) as "metadata_field_id",
  temp_openaire.title as "text_value",
  1 as "place"
FROM temp_funding INNER JOIN temp_openaire ON temp_funding.uri = temp_openaire.uri
WHERE temp_openaire.title IS NOT NULL;

-- Add metadatavalues dc.title
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, place)
SELECT
  item_id as "resource_id",
  2 as "resource_type_id",
  (select metadata_field_id from "metadatafieldregistry" WHERE metadata_schema_id = (SELECT metadata_schema_id FROM metadataschemaregistry WHERE "short_id" = 'dc') and element = 'title' and qualifier = 'alternative') as "metadata_field_id",
  temp_openaire.acronym as "text_value",
  1 as "place"
FROM temp_funding INNER JOIN temp_openaire ON temp_funding.uri = temp_openaire.uri
WHERE temp_openaire.acronym IS NOT NULL;

-- Add metadatavalues dc.identifier.uri
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, place)
SELECT
  item_id as "resource_id",
  2 as "resource_type_id",
  (select metadata_field_id from "metadatafieldregistry" WHERE metadata_schema_id = (SELECT metadata_schema_id FROM metadataschemaregistry WHERE "short_id" = 'dc') and element = 'identifier' and qualifier = 'uri') as "metadata_field_id",
  uri as "text_value",
  1 as "place"
FROM temp_funding
WHERE uri IS NOT NULL;

-- Add metadatavalues project.funder.name
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, place)
SELECT
  item_id as "resource_id",
  2 as "resource_type_id",
  (select metadata_field_id from "metadatafieldregistry" WHERE metadata_schema_id = (SELECT metadata_schema_id FROM metadataschemaregistry WHERE "short_id" = 'project') and element = 'funder' and qualifier = 'name') as "metadata_field_id",
  funder_name as "text_value",
  1 as "place"
FROM temp_funding
WHERE funder_name IS NOT NULL;

-- Add metadatavalues project.funder.identifier
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, place)
SELECT
  item_id as "resource_id",
  2 as "resource_type_id",
  (select metadata_field_id from "metadatafieldregistry" WHERE metadata_schema_id = (SELECT metadata_schema_id FROM metadataschemaregistry WHERE "short_id" = 'project') and element = 'funder' and qualifier = 'identifier') as "metadata_field_id",
  funder_identifier as "text_value",
  1 as "place"
FROM temp_funding
WHERE funder_identifier IS NOT NULL;

-- Add metadatavalues oaire.awardNumber
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, place)
SELECT
  item_id as "resource_id",
  2 as "resource_type_id",
  (select metadata_field_id from "metadatafieldregistry" WHERE metadata_schema_id = (SELECT metadata_schema_id FROM metadataschemaregistry WHERE "short_id" = 'oaire') and element = 'awardNumber' and qualifier IS NULL) as "metadata_field_id",
  projectid as "text_value",
  1 as "place"
FROM temp_funding
WHERE projectid IS NOT NULL;
 
-- Add metadatavalues oaire.fundingStream
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, place)
SELECT
  item_id as "resource_id",
  2 as "resource_type_id",
  (select metadata_field_id from "metadatafieldregistry" WHERE metadata_schema_id = (SELECT metadata_schema_id FROM metadataschemaregistry WHERE "short_id" = 'oaire') and element = 'fundingStream' and qualifier IS NULL) as "metadata_field_id",
  fundingprogramme as "text_value",
  1 as "place"
FROM temp_funding
WHERE fundingprogramme IS NOT NULL;

-- Add metadatavalues dc.description.provenance
INSERT INTO "metadatavalue" ( resource_id, metadata_field_id, text_value, resource_type_id, place) 
SELECT
	item_id as "resource_id",
	(select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM metadataschemaregistry as mr WHERE "short_id" = 'dc') and metadatafieldregistry.element = 'description' and metadatafieldregistry.qualifier = 'provenance') as "metadata_field_id",
	'Funded project created by RCAAP for DS7 migration at ' || NOW()::timestamp as "text_value",
	2 as "resource_type_id",
	1 as "place"
FROM temp_funding;

-- #### RELATIONSHIPS ######

CREATE SEQUENCE "project_relationship_seq";

-- CREATE TABLE "project_relationship" --------------------------------
CREATE TABLE "project_relationship" ( 
	"project_relationship_id" Integer DEFAULT nextval('project_relationship_seq'::regclass) NOT NULL,
	"project_item_id" Integer NOT NULL,
	"metadata_value_id" Integer NOT NULL,
	"item_id" Integer NOT NULL,
	"metadata_field_id" Integer,
	"text_value" Text,
	"place" Integer,
	PRIMARY KEY ( "project_relationship_id" ) );
 ;

INSERT INTO project_relationship (project_item_id, metadata_value_id, item_id, metadata_field_id, text_value, place)
SELECT
 temp_funding.item_id AS "project_item_id", 
 metadatavalue.metadata_value_id AS "metadata_value_id",
 metadatavalue.resource_id AS "item_id",
 metadatavalue.metadata_field_id AS "metadata_field_id",
 metadatavalue.text_value AS "text_value",
 metadatavalue.place AS "place"
FROM temp_funding
INNER JOIN metadatavalue ON temp_funding.uri = metadatavalue.text_value AND metadata_field_id IN (select metadata_field_id from metadatafieldregistry where metadata_schema_id=(select metadata_schema_id from metadataschemaregistry where short_id='dc') and element = 'relation');

COMMIT;

BEGIN;
-- apagar metadados authority existentes dos projetos
DELETE FROM "metadatavalue" WHERE "metadata_value_id" IN (SELECT "metadata_value_id" FROM "project_relationship");
COMMIT;

-- apagar a tabela temporaria do openaire com os projetos
BEGIN;
DROP TABLE IF EXISTS "temp_openaire" CASCADE;
COMMIT;