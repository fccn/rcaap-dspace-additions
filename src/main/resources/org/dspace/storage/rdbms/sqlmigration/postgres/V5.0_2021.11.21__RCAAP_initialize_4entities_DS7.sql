-- . Adicionar o suporte do campo "dspace.entity.type" schema: dspace http://dspace.org/dspace
-- . Criar communidade para entidades

BEGIN;

-- Criar schema para relacoes "relation.isAuthorOfPublication" e "relation.isPublicationOfAuthor"

INSERT INTO "metadataschemaregistry" ( "metadata_schema_id", "namespace", "short_id") 
VALUES (nextval('metadataschemaregistry_seq'), 'http://dspace.org/relation', 'relation' );
COMMIT;

BEGIN;
INSERT INTO "metadataschemaregistry" ( "metadata_schema_id", "namespace", "short_id") 
VALUES (nextval('metadataschemaregistry_seq'), 'http://namespace.openaire.eu/schema/oaire/', 'oaire' );
COMMIT;


BEGIN;
INSERT INTO "metadataschemaregistry" ( "metadata_schema_id", "namespace", "short_id") 
VALUES (nextval('metadataschemaregistry_seq'), 'http://dspace.org/dspace', 'dspace' );

INSERT INTO "metadatafieldregistry" ( "metadata_field_id","metadata_schema_id", "element", "qualifier") 
VALUES (nextval('metadatafieldregistry_seq'), (SELECT metadata_schema_id FROM "metadataschemaregistry" WHERE "short_id" = 'dspace'), 'entity', 'type' );
COMMIT;


BEGIN;

-- #### COMMUNITY ######
-- criar comunidade para Entidades
INSERT INTO "community" ( "community_id") 
VALUES ( nextval('community_seq') );

-- Criar metadatos da comunidade
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, text_lang, place)
values 
( currval('community_seq'), 
  4,
  ( select metadata_field_id 
    from metadatafieldregistry 
    where metadata_schema_id=(select metadata_schema_id from metadataschemaregistry where short_id='dc') 
      and element = 'title' and qualifier is null
  ),
  'Entidades', 
  null, 
  0
);
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, text_lang, place)
values 
( currval('community_seq'), 
  4,
  ( select metadata_field_id 
    from metadatafieldregistry 
    where metadata_schema_id=(select metadata_schema_id from metadataschemaregistry where short_id='dc') 
      and element = 'description' 
	  and qualifier = 'provenance'
  ),
  'Community created by RCAAP for entities migration at ' || NOW()::timestamp, 
  null, 
  0
);

-- action_id = 0 is READ
INSERT INTO "resourcepolicy" ( "policy_id", "resource_type_id", "resource_id", "action_id", "epersongroup_id") 
VALUES ( nextval('resourcepolicy_seq'), 4, currval('community_seq'), 0, 0 );

-- CRIAR HANDLE
INSERT INTO "handle" ( "handle_id", "handle", "resource_type_id", "resource_id") 
VALUES ( nextval('handle_seq'), (select substring(handle from 0 for position('/' in handle)) from handle order by handle_id DESC limit 1) || '/' || currval('handle_seq'), 4, currval('community_seq') );

COMMIT;


-- #### EPERSON ######
BEGIN;
-- Criar USER ADMIN para novo conteudo criado

INSERT INTO "public"."eperson" ( "eperson_id", "email", "can_log_in", "self_registered") 
VALUES ( nextval('eperson_seq'), 'dspace7@rcaap.pt', FALSE, TRUE );

-- Criar permissoes - administrador (group id:1)
INSERT INTO "public"."epersongroup2eperson" ( "id", "eperson_group_id", "eperson_id") 
VALUES ( nextval('epersongroup2eperson_seq'), 1, currval('eperson_seq') );

COMMIT;