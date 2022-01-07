-- Migrar todos os items para publicações
-- Definir o campo tipo de entidade para todas as coleções existentes

BEGIN;

-- Create dspace.entity.type = Publication for every item
INSERT INTO "metadatavalue" ( "metadata_value_id","resource_id", "metadata_field_id", "text_value", "resource_type_id") 
SELECT
	nextval('metadatavalue_seq') as "metadata_value_id",
	item.item_id as "resource_id",
	(select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM metadataschemaregistry as mr WHERE "short_id" = 'dspace') and metadatafieldregistry.element = 'entity' and metadatafieldregistry.qualifier = 'type') as "metadata_field_id",
	'Publication' as "text_value",
	2 as "resource_type_id"
FROM item;

COMMIT;

-- BEGIN;
-- -- adicionar tipo de entidade publicação a todos os itens relationados a authorprofiles
-- INSERT INTO "metadatavalue" ( "metadata_value_id","resource_id", "metadata_field_id", "text_value", "resource_type_id") 
-- SELECT
-- 	nextval('metadatavalue_seq') as "metadata_value_id",
-- 	item_id as "resource_id",
-- 	(select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'dspace') and metadatafieldregistry.element = 'entity' and metadatafieldregistry.qualifier = 'type') as "metadata_field_id",
-- 	'Publication' as "text_value",
-- 	2 as "resource_type_id"
-- FROM author_relationship
-- GROUP BY item_id;
-- 
-- COMMIT;


-- Set an entity type "Publication" for all existing collections
BEGIN;

INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, text_lang, place)
SELECT
	collection_id as "resource_id",
	3 as "resource_type_id",
	(select metadata_field_id from "metadatafieldregistry" WHERE metadata_schema_id = (SELECT metadata_schema_id FROM metadataschemaregistry WHERE "short_id" = 'dspace') and element = 'entity' and qualifier = 'type') as "metadata_field_id",
	'Publication' as "text_value",
	null as "text_lang",
	0 as "place"
FROM collection;

COMMIT;