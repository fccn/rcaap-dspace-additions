-- . Criar novas tabelas Audit
-- . Alterar scripts audit
-- . Migrar esquemas Degois

BEGIN;

CREATE TABLE IF NOT EXISTS "handle_audit_ds7" ( 
	"operation" Character( 1 ) NOT NULL,
	"stamp" Timestamp Without Time Zone NOT NULL,
	"userid" Text NOT NULL,
	"handle_id" Integer NOT NULL,
	"handle" Character Varying( 256 ),
	"resource_type_id" Integer,
	"resource_legacy_id" Integer,
	"resource_id" UUid );
 ;
COMMIT;

BEGIN;
CREATE TABLE IF NOT EXISTS "item_audit_ds7" ( 
	"operation" Character( 1 ) NOT NULL,
	"stamp" Timestamp Without Time Zone NOT NULL,
	"userid" Text NOT NULL,
	"item_id" Integer,
	"in_archive" Boolean,
	"withdrawn" Boolean,
	"last_modified" Timestamp With Time Zone,
	"discoverable" Boolean,
	"uuid" UUid NOT NULL,
	"submitter_id" UUid,
	"owning_collection" UUid
);
COMMIT;

BEGIN;

-- CREATE FUNCTION "process_handle_audit()" --------------------
CREATE OR REPLACE FUNCTION process_handle_audit()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
            INSERT INTO handle_audit_ds7 SELECT 'D', now(), user, OLD.*;
            RETURN OLD;
        ELSIF (TG_OP = 'UPDATE') THEN
            INSERT INTO handle_audit_ds7 SELECT 'U', now(), user, OLD.*;
            INSERT INTO handle_audit_ds7 SELECT 'U', now(), user, NEW.*;
            RETURN NEW;
        ELSIF (TG_OP = 'INSERT') THEN
            INSERT INTO handle_audit_ds7 SELECT 'I', now(), user, NEW.*;
            RETURN NEW;
        END IF;
        RETURN NULL;
    END;
$function$;
-- -------------------------------------------------------------

COMMIT;


BEGIN;

-- CREATE FUNCTION "process_item_audit()" ----------------------
CREATE OR REPLACE FUNCTION process_item_audit()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
            INSERT INTO item_audit_ds7 SELECT 'D', now(), user, OLD.*;
            RETURN OLD;
        ELSIF (TG_OP = 'INSERT') THEN
            INSERT INTO item_audit_ds7 SELECT 'I', now(), user, NEW.*;
            RETURN NEW;
        END IF;
        RETURN NULL;
    END;
$function$;
-- -------------------------------------------------------------

COMMIT;


-- -------------------------------------------------------------
-- ---------  atualizar metadados ------------------------------
-- -------------------------------------------------------------

BEGIN;

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element", "qualifier") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'oaire'), 'citation', 'startPage' );

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element", "qualifier") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'oaire'), 'citation', 'endPage' );

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element", "qualifier") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'oaire'), 'citation', 'volume' );

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element", "qualifier") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'oaire'), 'citation', 'title' );

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element", "qualifier") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'oaire'), 'citation', 'issue' );

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element", "qualifier") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'oaire'), 'citation', 'conferencePlace' );

COMMIT;

BEGIN;

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element", "qualifier") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'datacite'), 'subject', 'fos' );

COMMIT;

BEGIN;

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element", "qualifier") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'datacite'), 'subject', 'sdg' );

COMMIT;

BEGIN;

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'rcaap'), 'rights' );

COMMIT;

BEGIN;

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'rcaap'), 'type' );

COMMIT;
-- mover os field type id existentes do esquema degois para o esquema openaire
BEGIN;
UPDATE metadatavalue SET metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'oaire') and metadatafieldregistry.element = 'citation' and metadatafieldregistry.qualifier = 'startPage')
WHERE metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'degois') and metadatafieldregistry.element = 'publication' and metadatafieldregistry.qualifier = 'firstPage');

UPDATE metadatavalue SET metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'oaire') and metadatafieldregistry.element = 'citation' and metadatafieldregistry.qualifier = 'endPage')
WHERE metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'degois') and metadatafieldregistry.element = 'publication' and metadatafieldregistry.qualifier = 'lastPage');

UPDATE metadatavalue SET metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'oaire') and metadatafieldregistry.element = 'citation' and metadatafieldregistry.qualifier = 'volume')
WHERE metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'degois') and metadatafieldregistry.element = 'publication' and metadatafieldregistry.qualifier = 'volume');

UPDATE metadatavalue SET metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'oaire') and metadatafieldregistry.element = 'citation' and metadatafieldregistry.qualifier = 'title')
WHERE metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'degois') and metadatafieldregistry.element = 'publication' and metadatafieldregistry.qualifier = 'title');

UPDATE metadatavalue SET metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'oaire') and metadatafieldregistry.element = 'citation' and metadatafieldregistry.qualifier = 'issue')
WHERE metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'degois') and metadatafieldregistry.element = 'publication' and metadatafieldregistry.qualifier = 'issue');

UPDATE metadatavalue SET metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'oaire') and metadatafieldregistry.element = 'citation' and metadatafieldregistry.qualifier = 'conferencePlace')
WHERE metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'degois') and metadatafieldregistry.element = 'publication' and metadatafieldregistry.qualifier = 'location');

COMMIT;

-- mover os dc.subject.fos (do esquema RCAAP) para o esquema openaire em datacite.subject.fos
BEGIN;

UPDATE metadatavalue SET metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'datacite') and metadatafieldregistry.element = 'subject' and metadatafieldregistry.qualifier = 'fos')
WHERE metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'dc') and metadatafieldregistry.element = 'subject' and metadatafieldregistry.qualifier = 'fos');

-- apagar o campo antigo dc.subject.fos (nao pertence ao DC)
DELETE FROM "metadatafieldregistry" 
WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'dc') and metadatafieldregistry.element = 'subject' and metadatafieldregistry.qualifier = 'fos';

COMMIT;

-- mover os metadados dc.rights do tipo item para um campo específico RCAAP
BEGIN;

UPDATE metadatavalue SET metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'rcaap') and metadatafieldregistry.element = 'rights' and metadatafieldregistry.qualifier is NULL)
WHERE metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'dc') and metadatafieldregistry.element = 'rights' and metadatafieldregistry.qualifier is NULL)
AND resource_type_id = 2
AND LOWER(text_value) LIKE '%access';

COMMIT;


-- mover os dc.subject.ods (do esquema RCAAP) para o esquema openaire em datacite.subject.sdg
BEGIN;

UPDATE metadatavalue SET metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'datacite') and metadatafieldregistry.element = 'subject' and metadatafieldregistry.qualifier = 'sdg')
WHERE metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'dc') and metadatafieldregistry.element = 'subject' and metadatafieldregistry.qualifier = 'ods');

-- apagar o campo antigo dc.subject.ods (nao pertence ao DC)
DELETE FROM "metadatafieldregistry"
WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'dc') and metadatafieldregistry.element = 'subject' and metadatafieldregistry.qualifier = 'ods';

COMMIT;

-- mover os metadados dc.type do tipo item para um campo específico RCAAP
BEGIN;
UPDATE metadatavalue SET metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'rcaap') and metadatafieldregistry.element = 'type' and metadatafieldregistry.qualifier is NULL)
WHERE metadata_field_id = (select metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'dc') and metadatafieldregistry.element = 'type' and metadatafieldregistry.qualifier is NULL)
AND resource_type_id = 2
AND LOWER(text_value) IN ('article','bachelorThesis','masterThesis','doctoralThesis','book','bookPart','review','conferenceObject','lecture','workingPaper','preprint','report','annotation','contributionToPeriodical','patent','other','dataset');
COMMIT;

-- corrigir os dc types - para nova solução
-- Criar uma tabela temporária
BEGIN;
CREATE TEMPORARY TABLE temp_dctype(
   "text_value_in" text,
   "text_value_out" text
);

-- inserir valores de mapeamento
INSERT INTO temp_dctype ("text_value_out", "text_value_in")
VALUES
   ('text::periodical::journal::contribution to journal::journal article::research article','article'),
   ('text::thesis::bachelor thesis','bachelorThesis'),
   ('text::thesis::master thesis','masterThesis'),
   ('text::thesis::doctoral thesis','doctoralThesis'),
   ('text::book','book'),
   ('text::book::book part','bookPart'),
   ('text::review','review'),
   ('text::conference object','conferenceObject'),
   ('text::lecture','lecture'),
   ('text::working paper','workingPaper'),
   ('text::preprint','preprint'),
   ('text::report','report'),
   ('text::annotation','annotation'),
   ('text::periodical::journal::contribution to journal','contributionToPeriodical'),
   ('text::patent','patent'),
   ('other','other'),
   ('dataset','dataset');


-- mapear valores existentes rcaap.type
INSERT INTO "metadatavalue" ( "metadata_value_id","resource_id", "metadata_field_id", "text_value", "place", "resource_type_id") 
SELECT
	nextval('metadatavalue_seq') as "metadata_value_id",
	mdv.resource_id as "resource_id",
	(SELECT metadata_field_id from "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM metadataschemaregistry as mr WHERE "short_id" = 'dc') and metadatafieldregistry.element = 'type' and metadatafieldregistry.qualifier is NULL) as "metadata_field_id",
	text_value_out as "text_value",
	mdv.place as "place",
	mdv.resource_type_id as "resource_type_id"

FROM metadatavalue AS mdv 
LEFT JOIN temp_dctype ON mdv.text_value = text_value_in
WHERE mdv.metadata_field_id IN (SELECT metadata_field_id FROM "metadatafieldregistry" WHERE metadatafieldregistry.metadata_schema_id = (SELECT mr.metadata_schema_id FROM "metadataschemaregistry" as mr WHERE "short_id" = 'rcaap') AND metadatafieldregistry.element = 'type' AND metadatafieldregistry.qualifier is NULL);



COMMIT;