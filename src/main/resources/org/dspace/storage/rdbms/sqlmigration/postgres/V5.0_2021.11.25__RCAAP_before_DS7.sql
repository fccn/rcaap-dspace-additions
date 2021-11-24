-- . Criar novas tabelas Audit
-- . Alterar scripts audit

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