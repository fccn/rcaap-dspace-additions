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

# Configuração

## Configuraração Ciência Vitae
Será necessário adicionar as seguintes configurações ao local.cfg para suporte da API do CV:
```
# cienciavitae api
cienciavitae.url = https://qa.cienciavitae.pt

cienciavitae.api.url = ${cienciavitae.url}/api/v1.1
cienciavitae.api.username = USER
cienciavitae.api.password = PASS
```

O ficheiro pom.xml dos additions deve adicionar (já está incluido no source) como dependência a biblioteca (na versão correta):
```
<dependencies>
....
      <dependency>
      	<groupId>pt.rcaap</groupId>
      	<artifactId>cienciavitae.model</artifactId>
      	<version>0.0.1-SNAPSHOT</version>
      </dependency>
....
   </dependencies>
```

O ficheiro spring com a configuração do external source CienciaVitae: `src/main/resources/spring/external-cienciavitae.xml` deve ser copiado para: `[DSPACE]/config/spring/api`

## Configuraração Renates
Será necessário adicionar as seguintes configurações ao local.cfg para suporte da API do CV:
```
# Renates Importer
renates.api.url = https://renates.dgeec.mec.pt/ws/renatesws.asmx/Tese

```

O ficheiro spring com a configuração do external source CienciaVitae: `src/main/resources/spring/external-services-renates.xml` deve ser copiado para: `[DSPACE]/config/spring/api`

## Configuraração Tarefas de Curadoria
Será necessário adicionar as seguintes configurações ao local.cfg para suporte da API do CV:
```
# RCAAP Curation tasks
plugin.named.org.dspace.curate.CurationTask = org.dspace.ctask.general.VerifyTID = VerifyTID
plugin.named.org.dspace.curate.CurationTask = org.dspace.ctask.general.CheckDuplicates = CheckDuplicates
plugin.named.org.dspace.curate.CurationTask = org.dspace.ctask.general.EmbargoJustification = JustificationEmbargo
plugin.named.org.dspace.curate.CurationTask = org.dspace.ctask.general.DoiValidator = DoiValidator
plugin.named.org.dspace.curate.CurationTask = org.dspace.ctask.general.PolicyCheck = PolicyCheck
```