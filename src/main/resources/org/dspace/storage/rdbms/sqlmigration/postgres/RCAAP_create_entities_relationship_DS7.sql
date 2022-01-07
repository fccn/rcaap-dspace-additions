-- . Executar 
-- relation.isPublicationOfAuthor

-- #########################################

--            NOTA: 
--    Antes de executar este script, deverá 
--    ser carregado o modelo de entidades 
--    para a base de dados, bem como garantir
--    os registries


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



-- FINANCIAMENTO

BEGIN;
-- Criar as relações entre itens - excluindo repetições
INSERT INTO "relationship" ( "id","left_id", "right_id", "left_place", "right_place", "type_id") 
SELECT 
	nextval('relationship_id_seq') as "id",
	item.uuid as "left_id", 
	project.uuid as "right_id", 
	pr.place as "left_place",
	0 as "right_place", 
	(SELECT id FROM "relationship_type" where leftward_type = 'isProjectOfPublication'
		AND left_type = (select id from entity_type where label='Publication') 
		AND right_type = (select id from entity_type where label='Project')) as "type_id"
FROM (
	SELECT * FROM project_relationship
	WHERE project_relationship_id IN
		(SELECT MAX(project_relationship_id)
			FROM project_relationship
			GROUP BY item_id, project_item_id)) AS pr
INNER JOIN item as "project" on pr.project_item_id = project.item_id
INNER JOIN item as "item" on pr.item_id = item.item_id;

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



BEGIN;
-- DROP TABLE "project_relationship" ----------------------------
DROP TABLE IF EXISTS "project_relationship" CASCADE;
-- -------------------------------------------------------------
COMMIT;

BEGIN;
-- DROP SEQUENCE "project_relationship_seq" ---------------------
DROP SEQUENCE "project_relationship_seq" CASCADE;
-- -------------------------------------------------------------
COMMIT;
