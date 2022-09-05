-- #########################################

 -- Carregar modelo de entidades
BEGIN; 
INSERT INTO entity_type (id, label) VALUES
	(NEXTVAL('entity_type_id_seq'), 'none'),
	(NEXTVAL('entity_type_id_seq'), 'Publication'),
	(NEXTVAL('entity_type_id_seq'), 'Person'),
	(NEXTVAL('entity_type_id_seq'), 'OrgUnit'),
	(NEXTVAL('entity_type_id_seq'), 'Project');

INSERT INTO relationship_type (id, left_type, right_type, leftward_type, rightward_type, left_min_cardinality, left_max_cardinality, right_min_cardinality, right_max_cardinality, copy_to_left, copy_to_right, tilted) VALUES
	(NEXTVAL('relationship_type_id_seq'), 
	(SELECT id FROM entity_type WHERE label='Publication' LIMIT 1),
	(SELECT id FROM entity_type WHERE label='Person' LIMIT 1),
	'isAuthorOfPublication', 'isPublicationOfAuthor', 0, NULL, 0, NULL, false, false, 0),
	(NEXTVAL('relationship_type_id_seq'), 
	(SELECT id FROM entity_type WHERE label='Publication' LIMIT 1),
	(SELECT id FROM entity_type WHERE label='OrgUnit' LIMIT 1),
	'isAuthorOfPublication', 'isPublicationOfAuthor', 0, NULL, 0, NULL, false, false, 0),
	(NEXTVAL('relationship_type_id_seq'), 
	(SELECT id FROM entity_type WHERE label='Publication' LIMIT 1),
	(SELECT id FROM entity_type WHERE label='Person' LIMIT 1),
	'isContributorOfPublication', 'isPublicationOfContributor', 0, NULL, 0, NULL, false, false, 0),
	(NEXTVAL('relationship_type_id_seq'), 
	(SELECT id FROM entity_type WHERE label='Publication' LIMIT 1),
	(SELECT id FROM entity_type WHERE label='OrgUnit' LIMIT 1),
	'isContributorOfPublication', 'isPublicationOfContributor', 0, NULL, 0, NULL, false, false, 0),
	(NEXTVAL('relationship_type_id_seq'), 
	(SELECT id FROM entity_type WHERE label='Publication' LIMIT 1),
	(SELECT id FROM entity_type WHERE label='Project' LIMIT 1),
	'isProjectOfPublication', 'isPublicationOfProject', 0, NULL, 0, NULL, false, false, 0),
	(NEXTVAL('relationship_type_id_seq'),
	(SELECT id FROM entity_type WHERE label='Project' LIMIT 1),
	(SELECT id FROM entity_type WHERE label='OrgUnit' LIMIT 1),
	'isFundingAgencyOfProject', 'isProjectOfFundingAgency', 0, NULL, 0, NULL, false, false, 0);

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



-- FINANCIAMENTO

BEGIN;
-- Criar as relações entre itens - excluindo repetições (pub -> project)
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


-- ORGUNITS

BEGIN;
-- Criar as relações entre itens - excluindo repetições (Proj -> OrgUnit)
INSERT INTO "relationship" ( "id","left_id", "right_id", "left_place", "right_place", "type_id") 
SELECT 
	nextval('relationship_id_seq') as "id",
	project.uuid as "left_id", 
	orgunit.uuid as "right_id", 
	1 as "left_place",
	0 as "right_place", 
	(SELECT id FROM "relationship_type" where leftward_type = 'isFundingAgencyOfProject'
		AND left_type = (select id from entity_type where label='Project') 
		AND right_type = (select id from entity_type where label='OrgUnit')) as "type_id"
FROM (
	SELECT * FROM project_orgunit_relationship
	WHERE project_orgunit_relationship_id IN
		(SELECT MAX(project_orgunit_relationship_id)
			FROM project_orgunit_relationship
			GROUP BY org_unit_item_id, project_item_id)) AS pr
INNER JOIN item as "project" on pr.project_item_id = project.item_id
INNER JOIN item as "orgunit" on pr.org_unit_item_id = orgunit.item_id;

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



BEGIN;
-- DROP TABLE "project_orgunit_relationship" ----------------------------
DROP TABLE IF EXISTS "project_orgunit_relationship" CASCADE;
-- -------------------------------------------------------------
COMMIT;

BEGIN;
-- DROP SEQUENCE "project_orgunit_relationship_seq" ---------------------
DROP SEQUENCE "project_orgunit_relationship_seq" CASCADE;
-- -------------------------------------------------------------
COMMIT;



