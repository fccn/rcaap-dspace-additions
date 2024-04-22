-- #########################################

-- V7.1_2021.10.18__Fix_MDV_place_after_migrating_from_DSpace_5.sql
-- faz um reset ao campo place e isso impacta na ordem dos campos a apresentar
-- por isso este script deve ser executado posteriormente aquele script

-- Atualizar o campo place na tabela author_relationship
BEGIN;
UPDATE author_relationship AS ar SET place = (SELECT mv.place FROM metadatavalue as mv
	WHERE mv.metadata_value_id = ar.metadata_value_id);
COMMIT;

-- #########################################
-- Relações
-- #########################################

-- PESSOAS

BEGIN;
-- Criar as relações entre itens - excluindo repetições
INSERT INTO "relationship" ( "id","left_id", "right_id", "rightward_value", "left_place", "right_place", "type_id") 
SELECT 
	nextval('relationship_id_seq') as "id",
	item.uuid as "left_id", 
	author.uuid as "right_id", 
	ar.text_value as "rightward_value", 
	ar.place as "left_place",
	0 as "right_place", 
	(SELECT id FROM "relationship_type" where leftward_type = 'isAuthorOfPublication'
		AND left_type = (select id from entity_type where label='Publication') 
		AND right_type = (select id from entity_type where label='Person')) as "type_id"
FROM (
	SELECT * FROM author_relationship
	WHERE author_relationship_id IN
		(SELECT MAX(author_relationship_id)
			FROM author_relationship
			GROUP BY item_id, author_item_id)) AS ar
INNER JOIN item as "author" on ar.author_item_id = author.item_id
INNER JOIN item as "item" on ar.item_id = item.item_id;

COMMIT;


-- apagar os valores dos autores nos itens (agora sao entidades)
BEGIN;
DELETE FROM "metadatavalue" WHERE "metadata_value_id" IN (SELECT "metadata_value_id" FROM "author_relationship");
COMMIT;

-- apagar tabelas temporarias das relações

BEGIN;
-- DROP TABLE "author_relationship" ----------------------------
DROP TABLE IF EXISTS "author_relationship" CASCADE;
-- -------------------------------------------------------------
COMMIT;

BEGIN;
-- DROP SEQUENCE "author_relationship_seq" ---------------------
DROP SEQUENCE "author_relationship_seq" CASCADE;
-- -------------------------------------------------------------
COMMIT;
