# Instalação DSpace 7++

Obter o código DSpace versão 7.6
```
git clone --branch dspace-7.6 https://github.com/DSpace/DSpace.git /home/DSpace-7.6
```

Depois, garantir que o DSpace não tem os `additions` default.
```
cd /home/DSpace-7.6/dspace/modules/
mv additions /tmp/
```

Fazer clone do projeto para a diretoria additions em `/home/DSpace-7.6/dspace/modules/`:
```
git clone git@github.com:fccn/rcaap-dspace-additions.git additions
```

Depois, colocar as nossas configurações default:
```
mv additions/src/main/resources/config/ ../config
```

Definir o esquema de **virtual metadata** do OpenAIRE como sendo o default
```
cd ..
mv config/spring/api/virtual-metadata.xml config/spring/api/virtual-metadata.xml.origin
mv config/spring/api/virtual-metadata.xml.openaire4 config/spring/api/virtual-metadata.xml
```

Caso se use o Docker, será necessário alterar as dependências no Dockerfile e Dockerfile.cli para usar as imagens alojadas no Docker Hub do RCAAP:
```
sed -i 's/FROM dspace\/dspace-dependencies/FROM rcaap\/dspace-dependencies/g' Dockerfile
sed -i 's/FROM dspace\/dspace-dependencies/FROM rcaap\/dspace-dependencies/g' Dockerfile.cli
```

Depois deste processo, seguir os passos normais de instalação do DSpace. Ver: https://wiki.lyrasis.org/display/DSDOC7x/Installing+DSpace

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
                 <xsl:call-template name="dcRights">
                        </xsl:call-template>
        </xsl:template>-->
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

Primeiro seguir os passos referidos no tópico de **Instalação**.

Fazer o build da imagem Docker (dspace dependencies) (na raiz do DSpace):
```
cd /home/DSpace-7.6
docker build -t rcaap/dspace-dependencies -f Dockerfile.dependencies .
```

Agora disponibiliza-se essa imagem no Docker Hub porque será necessária para continuar o processo:
```
docker push rcaap/dspace-dependencies
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
docker push rcaap/dspace-dependencies
```
```
docker push rcaap/dspace
```
```
docker push rcaap/dspace-cli
```

As imagens ficarão disponibilizadas aqui:
https://hub.docker.com/u/rcaap
