-- . Adicionar o suporte do campo "relation.isAuthorOfPublication" schema e "relation.isPublicationOfAuthor"
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

-- Criar schema para relacoes "relation.isAuthorOfPublication" e "relation.isPublicationOfAuthor"

INSERT INTO "metadataschemaregistry" ( "metadata_schema_id", "namespace", "short_id") 
VALUES (nextval('metadataschemaregistry_seq'), 'http://dspace.org/relation', 'relation' );

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'relation'), 'isAuthorOfPublication');

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'relation'), 'isPublicationOfAuthor');

COMMIT;



BEGIN;

INSERT INTO "metadataschemaregistry" ( "metadata_schema_id", "namespace", "short_id") 
VALUES (nextval('metadataschemaregistry_seq'), 'http://dspace.org/dspace', 'dspace' );


INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element", "qualifier") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'dspace'), 'entity', 'type' );


INSERT INTO "metadatavalue" ( "metadata_value_id","resource_id", "metadata_field_id", "text_value", "resource_type_id") 
SELECT
	nextval('metadatavalue_seq') as "metadata_value_id",
	authorprofile.authorprofile_id as "resource_id",
	(select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'dspace') and metadatafieldregistry.element = 'entity' and metadatafieldregistry.qualifier = 'type') as "metadata_field_id",
	'Person' as "text_value",
	8 as "resource_type_id"
from authorprofile;

COMMIT;


BEGIN;

-- #### COMMUNITY ######
-- criar comunidade para Entidades
INSERT INTO "community" ( "community_id") 
VALUES ( nextval('community_seq') );
-- Criar metadatos da comunidade
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, text_lang, place)
values ( currval('community_seq'), 
 4,
(select metadata_field_id from metadatafieldregistry where metadata_schema_id=(select metadata_schema_id from metadataschemaregistry where short_id='dc') and element = 'title' and qualifier is null),
'Entidades', 
null, 
0);


-- action_id = 0 is READ
INSERT INTO "resourcepolicy" ( "policy_id", "resource_type_id", "resource_id", "action_id", "epersongroup_id") 
VALUES ( nextval('resourcepolicy_seq'), 4, currval('community_seq'), 0, 0 );


-- CRIAR HANDLE
INSERT INTO "public"."handle" ( "handle_id", "handle", "resource_type_id", "resource_id") 
VALUES ( nextval('handle_seq'), (select substring(handle from 0 for position('/' in handle)) from handle order by handle_id DESC limit 1) || '/' || currval('handle_seq'), 4, currval('community_seq') );


-- #### COLLECTION ######
-- criar coleção para pessoas

INSERT INTO "collection" ( "collection_id", "submitter") 
VALUES ( nextval('collection_seq'), (select eperson_id from eperson where eperson.email = 'rcaap@sdum.uminho.pt') );
-- Criar metadatos da colecção
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, text_lang, place)
values ( currval('collection_seq'), 3,
(select metadata_field_id from metadatafieldregistry where metadata_schema_id=(select metadata_schema_id from metadataschemaregistry where short_id='dc') and element = 'title' and qualifier is null),
'Pessoas', null, 0);
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, text_lang, place)
values ( currval('collection_seq'), 3,
(select metadata_field_id from "metadatafieldregistry" WHERE metadata_schema_id = (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'dspace') and element = 'entity' and qualifier = 'type'),
'Person', null, 0);


-- relação coleção-comunidade
INSERT INTO "community2collection" ( "id", "community_id", "collection_id") 
VALUES ( nextval('community2collection_seq'), currval('community_seq'), currval('collection_seq') );

-- action_id = 0 is READ
INSERT INTO "resourcepolicy" ( "policy_id", "resource_type_id", "resource_id", "action_id", "epersongroup_id") 
VALUES ( nextval('resourcepolicy_seq'), 3, currval('collection_seq'), 0, 0 );
-- action_id = 10 is DEFAULT ITEM READ
INSERT INTO "resourcepolicy" ( "policy_id", "resource_type_id", "resource_id", "action_id", "epersongroup_id") 
VALUES ( nextval('resourcepolicy_seq'), 3, currval('collection_seq'), 10, 0 );

-- CRIAR HANDLE
INSERT INTO "public"."handle" ( "handle_id", "handle", "resource_type_id", "resource_id") 
VALUES ( nextval('handle_seq'), (select substring(handle from 0 for position('/' in handle)) from handle order by handle_id DESC limit 1) || '/' || currval('handle_seq'), 3, currval('collection_seq') );

-- #### ITEM ######
-- criar coluna item_id no author profile
ALTER TABLE authorprofile
ADD "item_id" Integer;

-- atualizar o authorprofile com o novo item_id
UPDATE authorprofile SET item_id = nextval('item_seq');

-- criar item_id
INSERT INTO "item" ( "item_id", "submitter_id", "in_archive" , "withdrawn", "last_modified", "owning_collection", "discoverable") 
SELECT
	item_id,
	(SELECT eperson_id FROM eperson WHERE eperson.email = 'rcaap@sdum.uminho.pt') as "submitter_id",
	TRUE as "in_archive",
	FALSE as "withdrawn",
	last_modified,
	currval('collection_seq') as "owning_collection",
	TRUE as "discoverable"
FROM authorprofile;


INSERT INTO "resourcepolicy" ( "policy_id", "resource_type_id", "resource_id", "action_id", "epersongroup_id") 
SELECT
	nextval('resourcepolicy_seq') as "policy_id",
	2 as "resource_type_id",
	item_id as "resource_id",
	0 as "action_id",
	0 as "epersongroup_id"
FROM authorprofile;

INSERT INTO "collection2item" ( "id", "collection_id", "item_id") 
SELECT
	nextval('collection2item_seq') as "id",
	currval('collection_seq') as "collection_id",
	item_id as "item_id"
FROM authorprofile;

-- CRIAR HANDLE
INSERT INTO "public"."handle" ( "handle_id", "handle", "resource_type_id", "resource_id")
SELECT
	nextval('handle_seq') as "handle_id",
	(select substring(handle from 0 for position('/' in handle)) from handle order by handle_id DESC limit 1) || '/' || currval('handle_seq') as "handle",
	2 as "resource_type_id",
	item_id as "resource_id"
FROM authorprofile;

-- #### METADATAVALUE ######
-- mover metadata do author profile
UPDATE metadatavalue md SET resource_id = (select ap.item_id from authorprofile as ap where ap.authorprofile_id=md.resource_id), resource_type_id = 2
WHERE md.resource_type_id = 8;

COMMIT;


-- #### RELATIONSHIPS ######

BEGIN;
CREATE SEQUENCE "author_relationship_seq";
COMMIT;

BEGIN;

-- CREATE TABLE "author_relationship" --------------------------------
CREATE TABLE "author_relationship" ( 
	"author_relationship_id" Integer DEFAULT nextval('author_relationship_seq'::regclass) NOT NULL,
	"author_item_id" Integer NOT NULL,
	"metadata_value_id" Integer NOT NULL,
	"item_id" Integer NOT NULL,
	"metadata_field_id" Integer,
	"text_value" Text,
	"place" Integer,
	PRIMARY KEY ( "author_relationship_id" ) );
 ;
-- -------------------------------------------------------------

COMMIT;

BEGIN;

INSERT INTO "author_relationship" ("author_relationship_id", "author_item_id", "metadata_value_id", "item_id", "metadata_field_id", "text_value", "place" )
SELECT
	nextval('author_relationship_seq') as "author_relationship_id", 
	ap.item_id as "author_item_id",
	mv.metadata_value_id as "metadata_value_id", 
	mv.resource_id as "item_id",
	mv.metadata_field_id as "metadata_field_id",
	mv.text_value as "text_value",
	mv.place as "place"
FROM metadatavalue as mv inner join authorprofile as ap on ap.uuid = authority;

COMMIT;

BEGIN;
-- adicionar tipo de entidade publicação
INSERT INTO "metadatavalue" ( "metadata_value_id","resource_id", "metadata_field_id", "text_value", "resource_type_id") 
SELECT
	nextval('metadatavalue_seq') as "metadata_value_id",
	item_id as "resource_id",
	(select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'dspace') and metadatafieldregistry.element = 'entity' and metadatafieldregistry.qualifier = 'type') as "metadata_field_id",
	'Publication' as "text_value",
	2 as "resource_type_id"
FROM author_relationship
GROUP BY item_id;

COMMIT;

BEGIN;
DELETE FROM "metadatavalue" WHERE "metadata_value_id" IN (SELECT "metadata_value_id" FROM "author_relationship");
COMMIT;

BEGIN;
-- DROP TABLE "authorprofile" ----------------------------------
DROP TABLE IF EXISTS "authorprofile" CASCADE;
-- -------------------------------------------------------------
COMMIT;

BEGIN;
-- DROP SEQUENCE "authorprofile_seq" ---------------------------
DROP SEQUENCE IF EXISTS "authorprofile_seq" CASCADE;
-- -------------------------------------------------------------
COMMIT;


-- -------------------------------------------------------------
-- ---------  atualizar metadados ------------------------------
-- -------------------------------------------------------------

BEGIN;
-- -------------------------------------------------------------
INSERT INTO "metadataschemaregistry" ( "metadata_schema_id", "namespace", "short_id") 
VALUES (nextval('metadataschemaregistry_seq'), 'https://schema.org/Person', 'person' );

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'person'), 'familyName');

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'person'), 'givenName');

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'person'), 'identifier');

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element", "qualifier") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'person'), 'identifier', 'ciencia-id' );

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element", "qualifier") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'person'), 'identifier', 'orcid' );

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element", "qualifier") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'person'), 'identifier', 'rid' );

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element", "qualifier") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'person'), 'identifier', 'scopus-author-id' );


COMMIT;


-- mover os field type id existentes de author profile para os do schema.org/person
BEGIN;

UPDATE metadatavalue SET metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'dc') and metadatafieldregistry.element = 'title' and metadatafieldregistry.qualifier is NULL)
WHERE metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'authorProfile') and metadatafieldregistry.element = 'author' and metadatafieldregistry.qualifier IS NULL);

UPDATE metadatavalue SET metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'dc') and metadatafieldregistry.element = 'title' and metadatafieldregistry.qualifier = 'alternative')
WHERE metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'authorProfile') and metadatafieldregistry.element = 'name' and metadatafieldregistry.qualifier = 'variant');

UPDATE metadatavalue SET metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'dc') and metadatafieldregistry.element = 'subject' and metadatafieldregistry.qualifier = 'other')
WHERE metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'authorProfile') and metadatafieldregistry.element = 'specialization' and metadatafieldregistry.qualifier IS NULL);

UPDATE metadatavalue SET metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'person') and metadatafieldregistry.element = 'familyName' and metadatafieldregistry.qualifier is NULL)
WHERE metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'authorProfile') and metadatafieldregistry.element = 'name' and metadatafieldregistry.qualifier = 'last');

UPDATE metadatavalue SET metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'person') and metadatafieldregistry.element = 'givenName' and metadatafieldregistry.qualifier is NULL)
WHERE metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'authorProfile') and metadatafieldregistry.element = 'name' and metadatafieldregistry.qualifier = 'first');

UPDATE metadatavalue SET metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'person') and metadatafieldregistry.element = 'identifier' and metadatafieldregistry.qualifier = 'ciencia-id')
WHERE metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'authorProfile') and metadatafieldregistry.element = 'id' and metadatafieldregistry.qualifier = 'cienciaID');

UPDATE metadatavalue SET metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'person') and metadatafieldregistry.element = 'identifier' and metadatafieldregistry.qualifier = 'orcid')
WHERE metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'authorProfile') and metadatafieldregistry.element = 'id' and metadatafieldregistry.qualifier = 'orcid');

UPDATE metadatavalue SET metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'person') and metadatafieldregistry.element = 'identifier' and metadatafieldregistry.qualifier = 'rid')
WHERE metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'authorProfile') and metadatafieldregistry.element = 'id' and metadatafieldregistry.qualifier = 'researcherID');

UPDATE metadatavalue SET metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'person') and metadatafieldregistry.element = 'identifier' and metadatafieldregistry.qualifier = 'scopus-author-id')
WHERE metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'authorProfile') and metadatafieldregistry.element = 'id' and metadatafieldregistry.qualifier = 'scopusAuthorID');

UPDATE metadatavalue SET metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'person') and metadatafieldregistry.element = 'identifier' and metadatafieldregistry.qualifier is NULL)
WHERE metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'authorProfile') and metadatafieldregistry.element = 'id' and metadatafieldregistry.qualifier = 'other');

COMMIT;