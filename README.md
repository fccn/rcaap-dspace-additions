# Índice  
- [Instalação DSpace 7++](#instalação-dspace-7)
- [Configuração](#configuração)
- [Migração](#migração)
- [Docker](#docker)

# Instalação DSpace 7++

Obter o código DSpace versão 7.6.1. (nas instruções abaixo, substituir [dspace-7X] por dspace-7.6.1)
```
git clone --branch [dspace-7X] https://github.com/DSpace/DSpace.git DSpace
```

Depois, garantir que o DSpace não tem os `additions` default.
```
cd DSpace/dspace/modules/
mv additions /tmp/
```

Fazer clone do projeto para a diretoria additions em `DSpace/dspace/modules/`:
```
git clone https://github.com/fccn/rcaap-dspace-additions.git additions
```

Colocar as nossas configurações default:
```
rsync -r --remove-source-files  additions/src/main/resources/config/ ../config
```

Depois, colocar as nossas modificações SOLR:
```
rsync -r --remove-source-files  additions/src/main/resources/solr/ ../solr
```

Colocar também os ficheiros executáveis que estão no additions:
```
rsync -r --remove-source-files --chmod=Fu=rwx,Fg=rx,Fo=rx  additions/src/main/resources/bin/ ../bin
```


Definir o esquema de **virtual metadata** do OpenAIRE como sendo o default
```
cd ..
mv config/spring/api/virtual-metadata.xml config/spring/api/virtual-metadata.xml.origin
mv config/spring/api/virtual-metadata.xml.openaire4 config/spring/api/virtual-metadata.xml
```

# Configuração

## Configuração Ciência Vitae
Será necessário adicionar as seguintes configurações ao local.cfg para suporte da API do CV:
```
# cienciavitae api
cienciavitae.url = https://qa.cienciavitae.pt

cienciavitae.api.url = ${cienciavitae.url}/api/v1.1
cienciavitae.api.username = USER
cienciavitae.api.password = PASS
```

O ficheiro pom.xml nos `additions`, depois de seguir os passos da instalação, deverá já incluir a dependência necessária da biblioteca (neste caso, **não é necessário alterar**):
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

Depois de seguir os passos de instalação, deverá também existir um ficheiro na diretoria `[DSpace]/config/spring/api/external-cienciavitae.xml` com a configuração do serviço. Caso contrário, o ficheiro a usar estará disponível em: https://github.com/fccn/rcaap-dspace-additions/blob/main/src/main/resources/config/spring/api/external-cienciavitae.xml

## Configuração Submissão a partir do Ciência Vitae

Será necessário colocar no local.cfg a seguinte configuração:
```
# Ciencia Vitae specific SWORD import mapping stylesheet
crosswalk.submission.MODS.stylesheet = mods-rcaap_cienciavitae-submission.xslt
```

Depois de seguir os passos de instalação, deverá também existir um ficheiro na diretoria `[DSpace]/config/crosswalks/mods-rcaap_cienciavitae-submission.xsl` com a configuração do serviço. Caso contrário, o ficheiro a usar estará disponível em: https://github.com/fccn/rcaap-dspace-additions/blob/main/src/main/resources/config/crosswalks/mods-rcaap_cienciavitae-submission.xsl


Nota: Esta versão do xslt usa para o dc.type openaire4. Contudo, para quem não estiver a usar esta versão, deve optar por incluir a seguinte configuração:

```
 <!-- **** DC TYPE-->
        <xsl:template match="*[local-name()='genre']"> 
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">type</xsl:attribute>                      
                        <xsl:attribute name="lang">en_US</xsl:attribute>
                        <xsl:value-of select="normalize-space(.)"/>
                </xsl:element>
        </xsl:template>

        <!--<xsl:template match="*[local-name()='genre']"> 
                 <xsl:call-template name="dcType">
                        </xsl:call-template>
        </xsl:template>-->

Para repositórios que NÃO usem o esquema oiare e sim o esquema degois, devem alterar o oaire/citation de acordo com:

       oaire.citation.startPage -> degois.publication.firstPage
       oaire.citation.endPage --> depois.publicaiton.firstPage
       oaire.publication.title -> degois.publication.title
       oaire.publication.location -> degois.publication.location

       Os restantes oaire.citation mapear para degois.publication

```

## Configuraração Renates
Será necessário adicionar as seguintes configurações ao local.cfg para suporte da API do Renates:
```
# Renates (TID) API configurations
renates.api.url = https://renates.dgeec.mec.pt/ws/renatesws.asmx/Tese
```

Depois de seguir os passos de instalação, deverá também existir um ficheiro na diretoria `[DSpace]/config/spring/api/external-services-renates.xml` com a configuração do serviço. Caso contrário, o ficheiro a usar estará disponível em: https://github.com/fccn/rcaap-dspace-additions/blob/main/src/main/resources/config/spring/api/external-services-renates.xml


## Configuraração Tarefas de Curadoria

Será necessário adicionar as seguintes configurações ao local.cfg para suporte das tarefas de curadoria específicas RCAAP:
```
# RCAAP Curation tasks
plugin.named.org.dspace.curate.CurationTask = org.dspace.ctask.general.VerifyTID = VerifyTID
plugin.named.org.dspace.curate.CurationTask = org.dspace.ctask.general.CheckDuplicates = CheckDuplicates
plugin.named.org.dspace.curate.CurationTask = org.dspace.ctask.general.EmbargoJustification = JustificationEmbargo
plugin.named.org.dspace.curate.CurationTask = org.dspace.ctask.general.DoiValidator = DoiValidator
plugin.named.org.dspace.curate.CurationTask = org.dspace.ctask.general.PolicyCheck = PolicyCheck
```

# Migração

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

# Docker

Fazer clone do projeto:
```
git clone https://github.com/fccn/rcaap-dspace-additions.git
```

Fazer o build da imagem Docker (dspace):
```
docker build -t rcaap/dspace -f Dockerfile .
```

Fazer o build da imagem Docker (cli):
```
docker build -t rcaap/dspace-cli -f Dockerfile.cli .
```

E fazer o push das imagens para o Docker Hub para poder ser instalado em qualquer local:
```
docker push rcaap/dspace
```
```
docker push rcaap/dspace-cli
```

As imagens ficarão disponibilizadas aqui:
https://hub.docker.com/u/rcaap
