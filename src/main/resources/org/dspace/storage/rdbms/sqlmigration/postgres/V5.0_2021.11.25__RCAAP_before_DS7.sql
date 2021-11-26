-- . Criar novas tabelas Audit
-- . Alterar scripts audit
-- . Migrar esquemas Degois

BEGIN;

CREATE TABLE "handle_audit_ds7" ( 
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
CREATE TABLE "item_audit_ds7" ( 
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

INSERT INTO "metadataschemaregistry" ( "metadata_schema_id", "namespace", "short_id") 
VALUES (nextval('metadataschemaregistry_seq'), 'http://namespace.openaire.eu/schema/oaire/', 'oaire' );

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