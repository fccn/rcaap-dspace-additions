-- . Adicionar o suporte do campo "dspace.entity.type" schema: dspace http://dspace.org/dspace
-- . Criar communidade para entidades

BEGIN;

-- Criar schema para relacoes "relation.isAuthorOfPublication" e "relation.isPublicationOfAuthor"

INSERT INTO "metadataschemaregistry" ( "metadata_schema_id", "namespace", "short_id") 
VALUES (nextval('metadataschemaregistry_seq'), 'http://dspace.org/relation', 'relation' )
ON CONFLICT ("namespace") DO NOTHING;
COMMIT;

BEGIN;
INSERT INTO "metadataschemaregistry" ( "metadata_schema_id", "namespace", "short_id") 
VALUES (nextval('metadataschemaregistry_seq'), 'http://namespace.openaire.eu/schema/oaire/', 'oaire' )
ON CONFLICT ("namespace") DO NOTHING;
COMMIT;

BEGIN;
INSERT INTO "metadataschemaregistry" ( "metadata_schema_id", "namespace", "short_id") 
VALUES (nextval('metadataschemaregistry_seq'), 'http://datacite.org/schema/kernel-4', 'datacite' )
ON CONFLICT ("namespace") DO NOTHING;
COMMIT;

BEGIN;
INSERT INTO "metadataschemaregistry" ( "metadata_schema_id", "namespace", "short_id") 
VALUES (nextval('metadataschemaregistry_seq'), 'http://www.rcaap.pt/schema', 'rcaap' )
ON CONFLICT ("namespace") DO NOTHING;
COMMIT;

BEGIN;
INSERT INTO "metadataschemaregistry" ( "metadata_schema_id", "namespace", "short_id") 
VALUES (nextval('metadataschemaregistry_seq'), 'http://dspace.org/dspace', 'dspace' )
ON CONFLICT ("namespace") DO NOTHING;

-- registar o campo dspace.entity.type se ainda não existir
INSERT INTO "metadatafieldregistry" ("metadata_field_id", "metadata_schema_id", "element", "qualifier")
SELECT 
    nextval('metadatafieldregistry_seq'),
    m."metadata_schema_id",
    'entity',
    'type'
FROM "metadataschemaregistry" m
WHERE m."short_id" = 'dspace'
  AND NOT EXISTS (
        SELECT 1
        FROM "metadatafieldregistry" f
        WHERE f."metadata_schema_id" = m."metadata_schema_id"
          AND f."element" = 'entity'
          AND f."qualifier" = 'type'
    );
COMMIT;

-- registar campos dc.* necessários
BEGIN;

-- dc.title
INSERT INTO "metadatafieldregistry" ("metadata_field_id", "metadata_schema_id", "element")
SELECT 
    nextval('metadatafieldregistry_seq'),
    m."metadata_schema_id",
    'title'
FROM "metadataschemaregistry" m
WHERE m."short_id" = 'dc'
  AND NOT EXISTS (
        SELECT 1
        FROM "metadatafieldregistry" f
        WHERE f."metadata_schema_id" = m."metadata_schema_id"
          AND f."element" = 'title'
          AND f."qualifier" IS NULL
    );

-- dc.title.alternative
INSERT INTO "metadatafieldregistry" ("metadata_field_id", "metadata_schema_id", "element", "qualifier")
SELECT 
    nextval('metadatafieldregistry_seq'),
    m."metadata_schema_id",
    'title',
    'alternative'
FROM "metadataschemaregistry" m
WHERE m."short_id" = 'dc'
  AND NOT EXISTS (
        SELECT 1
        FROM "metadatafieldregistry" f
        WHERE f."metadata_schema_id" = m."metadata_schema_id"
          AND f."element" = 'title'
          AND f."qualifier" = 'alternative'
    );

-- dc.type
INSERT INTO "metadatafieldregistry" ("metadata_field_id", "metadata_schema_id", "element")
SELECT 
    nextval('metadatafieldregistry_seq'),
    m."metadata_schema_id",
    'type'
FROM "metadataschemaregistry" m
WHERE m."short_id" = 'dc'
  AND NOT EXISTS (
        SELECT 1
        FROM "metadatafieldregistry" f
        WHERE f."metadata_schema_id" = m."metadata_schema_id"
          AND f."element" = 'type'
          AND f."qualifier" IS NULL
    );

-- dc.description.abstract
INSERT INTO "metadatafieldregistry" ("metadata_field_id", "metadata_schema_id", "element", "qualifier")
SELECT 
    nextval('metadatafieldregistry_seq'),
    m."metadata_schema_id",
    'description',
    'abstract'
FROM "metadataschemaregistry" m
WHERE m."short_id" = 'dc'
  AND NOT EXISTS (
        SELECT 1
        FROM "metadatafieldregistry" f
        WHERE f."metadata_schema_id" = m."metadata_schema_id"
          AND f."element" = 'description'
          AND f."qualifier" = 'abstract'
    );

-- dc.description.provenance
INSERT INTO "metadatafieldregistry" ("metadata_field_id", "metadata_schema_id", "element", "qualifier")
SELECT 
    nextval('metadatafieldregistry_seq'),
    m."metadata_schema_id",
    'description',
    'provenance'
FROM "metadataschemaregistry" m
WHERE m."short_id" = 'dc'
  AND NOT EXISTS (
        SELECT 1
        FROM "metadatafieldregistry" f
        WHERE f."metadata_schema_id" = m."metadata_schema_id"
          AND f."element" = 'description'
          AND f."qualifier" = 'provenance'
    );

-- dc.identifier.uri
INSERT INTO "metadatafieldregistry" ("metadata_field_id", "metadata_schema_id", "element", "qualifier")
SELECT 
    nextval('metadatafieldregistry_seq'),
    m."metadata_schema_id",
    'identifier',
    'uri'
FROM "metadataschemaregistry" m
WHERE m."short_id" = 'dc'
  AND NOT EXISTS (
        SELECT 1
        FROM "metadatafieldregistry" f
        WHERE f."metadata_schema_id" = m."metadata_schema_id"
          AND f."element" = 'identifier'
          AND f."qualifier" = 'uri'
    );

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

-- garantir que temos grupo ANONYMOUS=0
-- avançar a sequência
SELECT nextval('epersongroup_seq');

INSERT INTO "epersongroup" ("eperson_group_id")
VALUES (0)
ON CONFLICT ("eperson_group_id") DO NOTHING;

-- Garantir o metadatavalue com o user anonimo
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, text_lang, place)
SELECT
    0,
    6,
    (
        SELECT metadata_field_id
        FROM metadatafieldregistry
        WHERE metadata_schema_id = (
            SELECT metadata_schema_id
            FROM metadataschemaregistry
            WHERE short_id = 'dc'
        )
        AND element = 'title'
        AND qualifier IS NULL
    ),
    'Anonymous',
    NULL,
    0
WHERE NOT EXISTS (
    SELECT 1
    FROM metadatavalue mv
    WHERE mv.resource_type_id = 6
      AND mv.text_value = 'Anonymous'
      AND metadata_field_id = (
        SELECT metadata_field_id
        FROM metadatafieldregistry
        WHERE metadata_schema_id = (
            SELECT metadata_schema_id
            FROM metadataschemaregistry
            WHERE short_id = 'dc'
        )
        AND element = 'title'
        AND qualifier IS NULL
      )
);

-- action_id = 0 is READ
INSERT INTO "resourcepolicy" ( "policy_id", "resource_type_id", "resource_id", "action_id", "epersongroup_id") 
VALUES ( nextval('resourcepolicy_seq'), 4, currval('community_seq'), 0, 0 );

-- CRIAR HANDLE
INSERT INTO "handle" ("handle_id", "handle", "resource_type_id", "resource_id")
VALUES (
    nextval('handle_seq'),
    COALESCE(
        (SELECT substring(handle FROM 0 FOR position('/' IN handle)) 
         FROM handle 
         ORDER BY handle_id DESC 
         LIMIT 1),
        '123456789'
    ) || '/' || currval('handle_seq'),
    4,
    currval('community_seq')
);

COMMIT;


-- #### EPERSON ######
BEGIN;
-- Criar USER ADMIN para novo conteudo criado

INSERT INTO "public"."eperson" ( "eperson_id", "email", "can_log_in", "self_registered") 
VALUES ( nextval('eperson_seq'), 'dspace7@rcaap.pt', FALSE, TRUE );

-- garantir que temos grupo ADMIN=1
-- avançar a sequência
SELECT nextval('epersongroup_seq');

INSERT INTO "epersongroup" ("eperson_group_id")
VALUES (1)
ON CONFLICT ("eperson_group_id") DO NOTHING;

-- Garantir o metadatavalue com o user admin
INSERT INTO metadatavalue (resource_id, resource_type_id, metadata_field_id, text_value, text_lang, place)
SELECT
    1,
    6,
    (
        SELECT metadata_field_id
        FROM metadatafieldregistry
        WHERE metadata_schema_id = (
            SELECT metadata_schema_id
            FROM metadataschemaregistry
            WHERE short_id = 'dc'
        )
        AND element = 'title'
        AND qualifier IS NULL
    ),
    'Administrator',
    NULL,
    0
WHERE NOT EXISTS (
    SELECT 1
    FROM metadatavalue mv
    WHERE mv.resource_type_id = 6
      AND mv.text_value = 'Administrator'
      AND metadata_field_id = (
        SELECT metadata_field_id
        FROM metadatafieldregistry
        WHERE metadata_schema_id = (
            SELECT metadata_schema_id
            FROM metadataschemaregistry
            WHERE short_id = 'dc'
        )
        AND element = 'title'
        AND qualifier IS NULL
      )
);


-- Criar permissoes - administrador (group id:1)
INSERT INTO "public"."epersongroup2eperson" ( "id", "eperson_group_id", "eperson_id") 
VALUES ( nextval('epersongroup2eperson_seq'), 1, currval('eperson_seq') );

COMMIT;