-- Fix duplicated epersons in groups:
BEGIN;
DELETE FROM epersongroup2eperson
    -- get all the otheres that are duplicated (NOT IN))
    WHERE id NOT IN
    (
        -- get all max(id) and grouping give one of each eperson_group_eperson)
        SELECT max(id)
        FROM epersongroup2eperson
        GROUP BY eperson_group_id, 
                 eperson_id
);
COMMIT;

-- Fix duplicated groups inside groups:
BEGIN;
DELETE FROM group2group
     -- get all the otheres that are duplicated (NOT IN))
    WHERE id NOT IN
    (
    -- get all max(id) and grouping give one of each parent and child)
        SELECT max(id)
        FROM group2group
        GROUP BY parent_id, 
                 child_id
    );
COMMIT;

-- Fix duplicated groups names:
BEGIN;
CREATE temp TABLE tempMDV(
  mvid INT 
);

INSERT INTO tempMDV (mvid)
SELECT m.metadata_value_id FROM metadatavalue m, 
    (SELECT max(metadata_value_id) as mvid, text_value FROM metadatavalue WHERE text_value IN(
        SELECT text_value FROM metadatavalue WHERE resource_type_id = 6
        GROUP by text_value
        HAVING count(*) > 1
    )
GROUP by text_value) as mdv
WHERE mdv.text_value = m.text_value and m.metadata_value_id <> mdv.mvid 
GROUP by m.metadata_value_id;

DELETE FROM metadatavalue WHERE metadata_value_id in (SELECT mvid FROM tempMDV);

COMMIT;


-- Fix duplicated workspaceitems (where item_id is duplicated):
BEGIN;
DELETE FROM workspaceitem
WHERE workspace_item_id IN (
                               SELECT workspaceitem.workspace_item_id
                               FROM workspaceitem
                                   INNER JOIN
                                   (
                                       SELECT item_id,
                                              max(workspace_item_id) AS workspace_item_id
                                       FROM workspaceitem
                                       GROUP by item_id
                                       HAVING count(*) > 1
                                   ) AS wspi
                                       ON workspaceitem.item_id = wspi.item_id
                                          AND wspi.workspace_item_id != workspaceitem.workspace_item_id
                           );


COMMIT;

-- Normalize bundle permissions

-- remove start_date from READ action of bundles for usergroup anonymous (fix embargo)
UPDATE resourcepolicy SET start_date = NULL
WHERE resource_type_id = 1
  AND action_id = 0
  AND resource_id IS NOT NULL
  AND start_date IS NOT NULL
  AND epersongroup_id = 0;

-- replace administrator  with anonymous from READ action of bundles (fix restricted)
UPDATE resourcepolicy SET epersongroup_id = 0
WHERE resource_type_id = 1
  AND action_id = 0
  AND resource_id IS NOT NULL
  AND start_date IS NULL
  AND epersongroup_id = 1;