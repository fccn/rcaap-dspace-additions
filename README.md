# rcaap-dspace-additions

Este projeto consiste nos incrementos necessários a tornar um DSpace num SARI.

## ANTES DA MIGRAÇÃO - Curadoria prévia na migração DSpace5++ - DSpace7++

Query necessária para identificar publicações com autores repetidos (se bem que estas repetições são ignoradas no processo de migração):
```
SELECT handle FROM handle
WHERE resource_id IN
   (SELECT resource_id from metadatavalue 
    INNER JOIN authorprofile on uuid = authority
    WHERE resource_type_id = 2
    GROUP BY resource_id, authority
    HAVING count(*) > 1) 
AND resource_type_id = 2;
```

Por inconsistencias, poderá existir duplicação de `item_id` para o workspaceitem. É necessário esta query para saber se há registos repetidos:
```
select item_id, count (*) from workspaceitem group by item_id having count(*)>1;
```
