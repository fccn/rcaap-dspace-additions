BEGIN;

-- Criar schema para relacoes "relation.isFundingAgencyOfProject"

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'relation'), 'isProjectOfFundingAgency');

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'relation'), 'isFundingAgencyOfProject');

COMMIT;

BEGIN;
-- -------------------------------------------------------------
INSERT INTO "metadataschemaregistry" ( "metadata_schema_id", "namespace", "short_id") 
VALUES (nextval('metadataschemaregistry_seq'), 'https://schema.org/Organization', 'organization' );

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'organization'), 'legalName');

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'organization'), 'identifier');

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element", "qualifier") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'organization'), 'identifier', 'ror' );

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element", "qualifier") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'organization'), 'identifier', 'isni' );


COMMIT;

BEGIN;

-- #### COLLECTION ######
-- criar coleção para projetos

-- Criar como administrador (o epersongroup_id do administrador)
INSERT INTO "collection" ( "collection_id") 
VALUES ( nextval('collection_seq') );

-- Criar metadatos da coleção
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, text_lang, place)
values ( currval('collection_seq'), 3,
(select metadata_field_id from metadatafieldregistry where metadata_schema_id=(select metadata_schema_id from metadataschemaregistry where short_id='dc') and element = 'title' and qualifier is null),
'Financiadores', null, 0);
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, text_lang, place)
values ( currval('collection_seq'), 3,
(select metadata_field_id from "metadatafieldregistry" WHERE metadata_schema_id = (SELECT metadata_schema_id FROM metadataschemaregistry WHERE "short_id" = 'dspace') and element = 'entity' and qualifier = 'type'),
'OrgUnit', null, 0);
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, text_lang, place)
values ( currval('collection_seq'), 3,
(select metadata_field_id from "metadatafieldregistry" WHERE metadata_schema_id = (SELECT metadata_schema_id FROM metadataschemaregistry WHERE "short_id" = 'dc') and element = 'description' and qualifier = 'abstract'),
'Organizações que atribuem financiamento', null, 0);
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, text_lang, place)
values ( currval('collection_seq'), 3,
(select metadata_field_id from "metadatafieldregistry" WHERE metadata_schema_id = (SELECT metadata_schema_id FROM metadataschemaregistry WHERE "short_id" = 'dc') and element = 'description' and qualifier = 'provenance'),
'Funders OrgUnit Collection created by RCAAP for DS7 migration at ' || NOW()::timestamp, null, 0);

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

CREATE TEMPORARY TABLE temp_funder(
   "item_id" Integer NOT NULL,
   "funder" VARCHAR, 
   "funder_name" VARCHAR,
   "funder_identifier" VARCHAR
);

INSERT INTO "temp_funder" ( "item_id", "funder", "funder_name" , "funder_identifier") 
VALUES (
	nextval('item_seq'), 
	'FCT',
	'Fundação para a Ciência e a Tecnologia',
	'http://doi.org/10.13039/501100001871'
);

INSERT INTO "temp_funder" ( "item_id", "funder", "funder_name" , "funder_identifier") 
VALUES (
	nextval('item_seq'), 
	'WT',
	'Welcome Trust',
	'http://doi.org/10.13039/100010269'
);

INSERT INTO "temp_funder" ( "item_id", "funder", "funder_name" , "funder_identifier") 
VALUES (
	nextval('item_seq'), 
	'EC',
	'European Commission',
	'http://doi.org/10.13039/501100008530'
);


-- Create item table
-- criar item_id
INSERT INTO "item" ( "item_id", "submitter_id", "in_archive" , "withdrawn", "last_modified", "owning_collection", "discoverable") 
SELECT
	item_id,
	(SELECT eperson_id FROM eperson WHERE eperson.email = 'dspace7@rcaap.pt') as "submitter_id",
	TRUE as "in_archive",
	FALSE as "withdrawn",
	NOW() as "last_modified",
	currval('collection_seq') as "owning_collection",
	TRUE as "discoverable"
FROM temp_funder;


INSERT INTO "resourcepolicy" ( "policy_id", "resource_type_id", "resource_id", "action_id", "epersongroup_id") 
SELECT
	nextval('resourcepolicy_seq') as "policy_id",
	2 as "resource_type_id",
	item_id as "resource_id",
	0 as "action_id",
	0 as "epersongroup_id"
FROM temp_funder;

INSERT INTO "collection2item" ( "id", "collection_id", "item_id") 
SELECT
	nextval('collection2item_seq') as "id",
	currval('collection_seq') as "collection_id",
	item_id as "item_id"
FROM temp_funder;

-- CRIAR HANDLE
INSERT INTO "handle" ( "handle_id", "handle", "resource_type_id", "resource_id")
SELECT
	nextval('handle_seq') as "handle_id",
	(select substring(handle from 0 for position('/' in handle)) from handle order by handle_id DESC limit 1) || '/' || currval('handle_seq') as "handle",
	2 as "resource_type_id",
	item_id as "resource_id"
FROM temp_funder;


-- ###  METADATA  ###

-- Create dspace.entity.type = Project for every funding
INSERT INTO "metadatavalue" ( resource_id, metadata_field_id, text_value, resource_type_id, place) 
SELECT
	item_id as "resource_id",
	(select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM metadataschemaregistry as mr WHERE "short_id" = 'dspace') and metadatafieldregistry.element = 'entity' and metadatafieldregistry.qualifier = 'type') as "metadata_field_id",
	'OrgUnit' as "text_value",
	2 as "resource_type_id",
	1 as "place"
FROM temp_funder;

-- Add metadatavalues dc.title
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, place)
SELECT
  item_id as "resource_id",
  2 as "resource_type_id",
  (select metadata_field_id from "metadatafieldregistry" WHERE metadata_schema_id = (SELECT metadata_schema_id FROM metadataschemaregistry WHERE "short_id" = 'dc') and element = 'title' and qualifier is NULL) as "metadata_field_id",
  funder_name as "text_value",
  1 as "place"
FROM temp_funder;

-- Add metadatavalues dc.type
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, place)
SELECT
  item_id as "resource_id",
  2 as "resource_type_id",
  (select metadata_field_id from "metadatafieldregistry" WHERE metadata_schema_id = (SELECT metadata_schema_id FROM metadataschemaregistry WHERE "short_id" = 'dc') and element = 'type' and qualifier is NULL) as "metadata_field_id",
  'FundingOrganization' as "text_value",
  1 as "place"
FROM temp_funder;

-- Add metadatavalues dc.title.alternative
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, place)
SELECT
  item_id as "resource_id",
  2 as "resource_type_id",
  (select metadata_field_id from "metadatafieldregistry" WHERE metadata_schema_id = (SELECT metadata_schema_id FROM metadataschemaregistry WHERE "short_id" = 'dc') and element = 'title' and qualifier = 'alternative') as "metadata_field_id",
  funder as "text_value",
  1 as "place"
FROM temp_funder;

-- Add metadatavalues organization.legalName
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, place)
SELECT
  item_id as "resource_id",
  2 as "resource_type_id",
  (select metadata_field_id from "metadatafieldregistry" WHERE metadata_schema_id = (SELECT metadata_schema_id FROM metadataschemaregistry WHERE "short_id" = 'organization') and element = 'legalName' and qualifier is NULL) as "metadata_field_id",
  funder_name as "text_value",
  1 as "place"
FROM temp_funder;

-- Add metadatavalues project.funder.identifier
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, place)
SELECT
  item_id as "resource_id",
  2 as "resource_type_id",
  (select metadata_field_id from "metadatafieldregistry" WHERE metadata_schema_id = (SELECT metadata_schema_id FROM metadataschemaregistry WHERE "short_id" = 'organization') and element = 'identifier' and qualifier is NULL) as "metadata_field_id",
  funder_identifier as "text_value",
  1 as "place"
FROM temp_funder;

-- Add metadatavalues dc.description.provenance
INSERT INTO "metadatavalue" ( resource_id, metadata_field_id, text_value, resource_type_id, place) 
SELECT
	item_id as "resource_id",
	(select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM metadataschemaregistry as mr WHERE "short_id" = 'dc') and metadatafieldregistry.element = 'description' and metadatafieldregistry.qualifier = 'provenance') as "metadata_field_id",
	'Funder entity created by RCAAP for DS7 migration at ' || NOW()::timestamp as "text_value",
	2 as "resource_type_id",
	1 as "place"
FROM temp_funder;

COMMIT;