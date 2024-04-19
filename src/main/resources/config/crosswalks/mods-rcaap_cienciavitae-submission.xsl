<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:dim="http://www.dspace.org/xmlns/dspace/dim"
                xmlns:mods="http://www.loc.gov/mods/v3"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                version="1.0">
<!--
                **************************************************
                MODS-2-DIM  ("DSpace Intermediate Metadata" ~ Dublin Core variant)
                For a DSpace INGEST Plug-In Crosswalk
                William Reilly wreilly@mit.edu
                INCOMPLETE
                but as Work-In-Progress, should satisfy current project with CSAIL.
                See: http://cwspace.mit.edu/docs/WorkActivity/Metadata/Crosswalks/QDC-MODS/CSAILQDC-MODSxwalkv1p0.pdf
                Last modified: November 14, 2005
http://cwspace.mit.edu/docs/WorkActivity/Metadata/Crosswalks/MODS-2-DIM/CSAILMODS.xml
http://cwspace.mit.edu/docs/WorkActivity/Metadata/Crosswalks/MODS-2-DIM/MODS-2-DIM.xslt
http://cwspace.mit.edu/docs/WorkActivity/Metadata/Crosswalks/MODS-2-DIM/CSAIL-DIMfromMODS.xml

 Author:   William Reilly
 Revision: $Revision$
 Date:     $Date$


     **************************************************
-->

        <!-- This XSLT file (temporarily, in development)
[wreilly ~/Documents/CWSpace/WorkActivityLOCAL/Metadata/Crosswalks/MODS-2-DIM ]$MODS-2-DIM.xslt

$ scp MODS-2-DIM.xslt athena.dialup.mit.edu:~/Private/

        See also mods.properties in same directory.
        e.g. dc.contributor = <mods:name><mods:namePart>%s</mods:namePart></mods:name> | mods:namePart/text()
-->

        <!-- Source XML:
                CSAIL example
                http://cwspace.mit.edu/docs/WorkActivity/Metadata/Crosswalks/QDC-MODS/CSAILQDC-MODSxwalkv1p0.pdf

        Important to See Also: "DCLib (DSpace) to MODS mapping == Dublin Core with Qualifiers==DSpace application"              http://cwspace.mit.edu/docs/WorkActivity/Metadata/Crosswalks/MODSmapping2MB.html

        See Also: e.g.  MODS Sample: "Article in a serial"
                http://www.loc.gov/standards/mods/v3/modsjournal.xml
        -->
                
        <!-- Target XML:
                http://wiki.dspace.org/DspaceIntermediateMetadata
                
                e.g. <dim:dim xmlns:dim="http://www.dspace.org/xmlns/dspace/dim">
                <dim:field mdschema="dc" element="title" lang="en_US">CSAIL Title - The Urban Question as a Scale Question</dim:field>
                <dim:field mdschema="dc" element="contributor" qualifier="author" lang="en_US">Brenner, Neil</dim:field>
                ...
        -->


        <!-- Dublin Core schema links:
                        http://dublincore.org/schemas/xmls/qdc/2003/04/02/qualifieddc.xsd
                        http://dublincore.org/schemas/xmls/qdc/2003/04/02/dcterms.xsd  -->

        <xsl:output indent="yes" method="xml"/>
        <!-- Unnecessary attribute:
                xsl:exclude-result-prefixes=""/> -->



<!-- WR_ Unnecessary, apparently.
        <xsl:template match="@* | node()">
                <xsl:copy>
                        <xsl:apply-templates select="@* | node()"/>
                </xsl:copy>
        </xsl:template>
-->
        
<!-- WR_ Unnecessary, apparently.
        <xsl:template match="/">
                <xsl:apply-templates/>
        </xsl:template>
-->

        <xsl:template match="text()">
                <!--
                                Do nothing.

                                Override, effectively, the "Built-In" rule which will
                                process all text inside elements otherwise not matched by any xsl:template.

                                Note: With this in place, be sure to then provide templates or "value-of"
                                statements to actually _get_ the (desired) text out to the result document!
                -->
        </xsl:template>


<!-- **** MODS  mods  [ROOT ELEMENT] ====> DC n/a **** -->
        <xsl:template match="*[local-name()='mods']">
                <!-- fwiw, these match approaches work:
                        <xsl:template match="mods:mods">...
                        <xsl:template match="*[name()='mods:mods']">...
                        <xsl:template match="*[local-name()='mods']">...
                        ...Note that only the latter will work on XML data that does _not_ have
                        namespace prefixes (e.g. <mods><titleInfo>... vs. <mods:mods><mods:titleInfo>...)
                -->
                <xsl:element name="dim:dim">

        <xsl:comment>IMPORTANT NOTE:
                ****************************************************************************************************
                THIS "Dspace Intermediate Metadata" ('DIM') IS **NOT** TO BE USED FOR INTERCHANGE WITH OTHER SYSTEMS.
                ****************************************************************************************************
                It does NOT pretend to be a standard, interoperable representation of Dublin Core.

                It is expressly used for transformation to and from source metadata XML vocabularies into and out of the DSpace object model.

                See http://wiki.dspace.org/DspaceIntermediateMetadata

                For more on Dublin Core standard schemata, see:
                        http://dublincore.org/schemas/xmls/qdc/2003/04/02/qualifieddc.xsd
                        http://dublincore.org/schemas/xmls/qdc/2003/04/02/dcterms.xsd

        </xsl:comment>


<!-- WR_ NAMESPACE NOTE
        Don't "code into" this XSLT the creation of the attribute with the name 'xmlns:dim', to hold the DSpace URI for that namespace.
        NO: <dim:field mdschema="dc" element="title" lang="en_US" xmlns:dim="http://www.dspace.org/xmlns/dspace/dim">
        Why not?
        Because it's an error (or warning, at least), and because the XML/XSLT tools (parsers, processors) will take care of it for you. ("Ta-da!")
        [fwiw, I tried this on 4 processors: Sablotron, libxslt, Saxon, and Xalan-J (using convenience of TestXSLT http://www.entropy.ch/software/macosx/ ).]
        -->
<!-- WR_ Do Not Use (see above note)
                <xsl:attribute name="xmlns:dim">http://www.dspace.org/xmlns/dspace/dim</xsl:attribute>
        -->
                        <xsl:apply-templates/>
                </xsl:element>
        </xsl:template>

<!-- **** MODS   titleInfo/title ====> DC title **** -->
        <xsl:template match="*[local-name()='titleInfo']/*[local-name()='title']">
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">title</xsl:attribute>
                        <xsl:attribute name="lang">en_US</xsl:attribute>
                        <xsl:value-of select="normalize-space(.)"/>
                </xsl:element>
        </xsl:template>


<!-- **** MODS   titleInfo/subTitle ====> DC title ______ (?) **** -->
        <!-- TODO No indication re: 'subTitle' from this page:
                http://cwspace.mit.edu/docs/WorkActivity/Metadata/Crosswalks/MODSmapping2MB.html
                -->
        <!-- (Not anticipated from CSAIL.) -->
<!--
        <xsl:template match="*[local-name()='titleInfo']/*[local-name()='subTitle']">
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">title</xsl:attribute>
                        <xsl:attribute name="qualifier">SUB-TITLE (TODO ?)</xsl:attribute>
                        <xsl:attribute name="lang">en_US</xsl:attribute>
                        <xsl:value-of select="normalize-space(.)"/>
                </xsl:element>
        </xsl:template>
-->

<!-- **** MODS   titleInfo/@type="alternative" ====> DC title.alternative **** -->
        <xsl:template match="*[local-name()='titleInfo'][@type='alternative']">
                <!-- TODO Three other attribute values:
                        http://www.loc.gov/standards/mods/mods-outline.html#titleInfo
                        -->
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">title</xsl:attribute>
                        <xsl:attribute name="qualifier">alternative</xsl:attribute>
                        <xsl:attribute name="lang">en_US</xsl:attribute>
                        <xsl:value-of select="normalize-space(.)"/>
                </xsl:element>
        </xsl:template>



<!-- **** MODS  name ====> DC  contributor.{role/roleTerm} **** -->
        <xsl:template match="*[local-name()='name']">
            <xsl:choose>
                <xsl:when test="./@type='personal'">
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">contributor</xsl:attribute>
                        <!-- Important assumption: That the string value used
                                in the MODS role/roleTerm is indeed a DC Qualifier.
                                e.g. contributor.illustrator
                                (Using this assumption, rather than coding in
                                a more controlled vocabulary via xsl:choose etc.)
                                -->
                        <xsl:attribute name="qualifier"><xsl:value-of select="*[local-name()='role']/*[local-name()='roleTerm']"/></xsl:attribute>
                        <xsl:attribute name="lang">en_US</xsl:attribute>
<!-- TODO: Logic (xsl:choose) re: format of names in source XML (e.g. Smith, John; or Fname and Lname in separate elements, etc.) -->
<!-- Used for CSAIL == simply:
                        <namePart>Lname, Fname</namePart>
-->
                        <xsl:value-of select="*[local-name()='namePart']"/>

<!-- Not Used for CSAIL
                        <namePart type="family">Lname</namePart> <namePart type="given">Fname</namePart>
-->
<!--    (Therefore, not used here)
                        <xsl:value-of select="*[local-name()='namePart'][@type='given']"/><xsl:text> </xsl:text><xsl:value-of select="*[local-name()='namePart'][@type='family']"/>
-->
        </xsl:element>
    </xsl:when>
    <xsl:when test="./@type='conference' and ../*[local-name()='genre']/text()='conferenceObject'">
         <xsl:element name="dim:field">
            <xsl:attribute name="mdschema">oaire</xsl:attribute>
            <xsl:attribute name="element">citation</xsl:attribute>
            <xsl:attribute name="qualifier">title</xsl:attribute>
            <xsl:attribute name="lang">en_US</xsl:attribute>
            <xsl:value-of select="*[local-name()='namePart']"/>
        </xsl:element>                
    </xsl:when>
</xsl:choose>

</xsl:template>


<!-- **** MODS   originInfo/dateCreated ====> DC  date.created **** -->
        <xsl:template match="*[local-name()='originInfo']/*[local-name()='dateCreated']">
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">date</xsl:attribute>
                        <xsl:attribute name="qualifier">created</xsl:attribute>
                        <xsl:attribute name="lang">en_US</xsl:attribute>
                        <xsl:value-of select="."/>
                </xsl:element>
        </xsl:template>

<!-- **** MODS   originInfo/dateIssued ====> DC  date.issued **** -->
        <xsl:template match="*[local-name()='originInfo']/*[local-name()='dateIssued']">
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">date</xsl:attribute>
                        <xsl:attribute name="qualifier">issued</xsl:attribute>
                        <xsl:attribute name="lang">en_US</xsl:attribute>
                        <xsl:value-of select="."/>
                </xsl:element>
        </xsl:template>


<!-- **** MODS   physicalDescription/extent ====> DC  format.extent **** -->
        <xsl:template match="*[local-name()='physicalDescription']/*[local-name()='extent']">
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">format</xsl:attribute>                    <xsl:attribute name="qualifier">extent</xsl:attribute>
                        <xsl:attribute name="lang">en_US</xsl:attribute>
                        <xsl:value-of select="."/>
                </xsl:element>
        </xsl:template>

<!-- **** MODS   abstract  ====> DC  description.abstract **** -->
        <xsl:template match="*[local-name()='abstract']">
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">description</xsl:attribute>                       <xsl:attribute name="qualifier">abstract</xsl:attribute>
                        <xsl:attribute name="lang">en_US</xsl:attribute>
                        <xsl:value-of select="normalize-space(.)"/>
                </xsl:element>
        </xsl:template>


<!-- **** MODS   subject/topic ====> DC  subject **** -->
        <xsl:template match="*[local-name()='subject']/*[local-name()='topic']">
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">subject</xsl:attribute>                   <xsl:attribute name="lang">en_US</xsl:attribute>
                        <xsl:value-of select="normalize-space(.)"/>
                </xsl:element>
        </xsl:template>


<!-- **** MODS   subject/geographic ====> DC  coverage.spatial **** -->
        <!-- (Not anticipated for CSAIL.) -->
        <xsl:template match="*[local-name()='subject']/*[local-name()='geographic']">
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">coverage</xsl:attribute>                                                  <xsl:attribute name="qualifier">spatial</xsl:attribute>
                        <xsl:attribute name="lang">en_US</xsl:attribute>
                        <xsl:value-of select="normalize-space(.)"/>
                </xsl:element>
        </xsl:template>

<!-- **** MODS   subject/temporal ====> DC  coverage.temporal **** -->
        <!-- (Not anticipated for CSAIL.) -->
        <xsl:template match="*[local-name()='subject']/*[local-name()='temporal']">
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">coverage</xsl:attribute>                                                  <xsl:attribute name="qualifier">temporal</xsl:attribute>
                        <xsl:attribute name="lang">en_US</xsl:attribute>
                        <xsl:value-of select="normalize-space(.)"/>
                </xsl:element>
        </xsl:template>


<!-- **** MODS   relatedItem...    **** -->
        <!-- NOTE -
                HAS *TWO* INTERPRETATIONS IN DC:
                1) DC  identifier.citation
                MODS [@type='host'] {/part/text}       ====> DC  identifier.citation
                2) DC  relation.___
                MODS [@type='____'] {/titleInfo/title} ====> DC  relation.{ series | host | other...}
        -->
        <xsl:template match="*[local-name()='relatedItem']">
                <!--<xsl:choose> 
                        <xsl:when test="*[local-name()='name']/*[local-name()='role'] and ./@type='host'">-->
                            <xsl:for-each select="*[local-name()='name']">
                                <xsl:choose>
                                    <xsl:when test="*[local-name()='role']">
                                        <xsl:element name="dim:field">
                                                <xsl:attribute name="mdschema">dc</xsl:attribute>
                                                <xsl:attribute name="element">contributor</xsl:attribute>
                                                <xsl:attribute name="qualifier"><xsl:value-of select="normalize-space(*[local-name()='role']/*[local-name()='roleTerm'])"/></xsl:attribute>
                                                <xsl:attribute name="lang">en_US</xsl:attribute>
                                                <xsl:value-of select="normalize-space(*[local-name()='namePart'])"/>
                                        </xsl:element>
                                    </xsl:when>
                                </xsl:choose>
                                <!-- Note: CSAIL Assumption (and for now, generally):
                                        The bibliographic citation is _not_ parsed further,
                                        and one single 'text' element will contain it.
                                        e.g. <text>Journal of Physics, v. 53, no. 9, pp. 34-55, Aug. 15, 2004</text>
                                        -->
                            </xsl:for-each>

                       <!-- </xsl:when>



                        
                </xsl:choose>-->

                <xsl:choose>
                        <!-- 1)  DC  identifier.citation  -->
                        <xsl:when test="./@type='host'  and   *[local-name()='part']/*[local-name()='text']">
                                <xsl:element name="dim:field">
                                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                                        <xsl:attribute name="element">identifier</xsl:attribute>
                                        <xsl:attribute name="qualifier">citation</xsl:attribute>
                                        <xsl:attribute name="lang">en_US</xsl:attribute>
                                        <xsl:value-of select="normalize-space(*[local-name()='part']/*[local-name()='text'])"/>
                                </xsl:element>
                                <!-- Note: CSAIL Assumption (and for now, generally):
                                        The bibliographic citation is _not_ parsed further,
                                        and one single 'text' element will contain it.
                                        e.g. <text>Journal of Physics, v. 53, no. 9, pp. 34-55, Aug. 15, 2004</text>
                                        -->
                        </xsl:when>

  

                        <!-- Projects -->
                        <xsl:when test="./@xlink:href!=''">
                            <xsl:element name="dim:field">
                                <xsl:attribute name="mdschema">dc</xsl:attribute>
                                <xsl:attribute name="element">relation</xsl:attribute>
                                <xsl:attribute name="lang">en_US</xsl:attribute>
                                <xsl:value-of select="normalize-space(./@xlink:href)"/>    
                            </xsl:element>
                        </xsl:when>
                        <!-- 3)  DC  relation._____  -->
                        <xsl:otherwise>
                                <xsl:choose>
                                    <xsl:when test="./@type='series'">
                                        <xsl:element name="dim:field">
                                            <xsl:attribute name="mdschema">dc</xsl:attribute>
                                            <xsl:attribute name="element">relation</xsl:attribute>
                                            <xsl:attribute name="qualifier">ispartofseries</xsl:attribute>
                                            <xsl:attribute name="lang">en_US</xsl:attribute>
                                            <xsl:value-of select="normalize-space(*[local-name()='titleInfo']/*[local-name()='title'])"/>
                                        </xsl:element>
                                    </xsl:when>
                                     <xsl:when test="./@type='host'">
                                        <xsl:choose>
                                            <xsl:when test="not(../*[local-name()='name'][@type='conference'])">
                                                <xsl:element name="dim:field">
                                                    <xsl:attribute name="mdschema">oaire</xsl:attribute>
                                                    <xsl:attribute name="element">citation</xsl:attribute>
                                                    <xsl:attribute name="qualifier">title</xsl:attribute>
                                                    <xsl:attribute name="lang">en_US</xsl:attribute>
                                                    <xsl:value-of select="normalize-space(*[local-name()='titleInfo']/*[local-name()='title'])"/>
                                                </xsl:element>
                                            </xsl:when>
                                        </xsl:choose>
                                            <!--<xsl:element name="dim:field">
                                            <xsl:attribute name="mdschema">dc</xsl:attribute>
                                            <xsl:attribute name="element">relation</xsl:attribute>
                                            <xsl:attribute name="qualifier">ispartof</xsl:attribute>
                                            <xsl:attribute name="lang">en_US</xsl:attribute>
                                            <xsl:value-of select="normalize-space(*[local-name()='titleInfo']/*[local-name()='title'])"/>
                                        </xsl:element>-->
                                    </xsl:when>
                                </xsl:choose>
                        </xsl:otherwise>
                </xsl:choose>
        </xsl:template>



<!-- **** MODS   identifier/@type  ====> DC identifier.other  **** -->
       <!-- <xsl:template match="*[local-name()='identifier']"> --><!-- [@type='series']"> -->
       <!--         <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">identifier</xsl:attribute>
                        <xsl:choose>
                                <xsl:when test="./@type='local'">
                                        <xsl:attribute name="qualifier">other</xsl:attribute>
                                </xsl:when>
                                <xsl:when test="./@type='uri'">
                                        <xsl:attribute name="qualifier">uri</xsl:attribute>
                                </xsl:when>-->
                                <!-- 6 (?) more... TODO
                                        http://cwspace.mit.edu/docs/WorkActivity/Metadata/Crosswalks/MODSmapping2MB.html
                                        http://www.loc.gov/standards/mods/mods-outline.html#identifier
                                        
                                        (but see also MODS relatedItem[@type="host"]/part/text == identifier.citation)
                                -->
                        <!--</xsl:choose>
                        <xsl:attribute name="lang">en_US</xsl:attribute>
                        <xsl:value-of select="normalize-space(.)"/>
                </xsl:element>
        </xsl:template>-->


    <!-- CHANGED IDENTIFIER TO USE THE VALUES FROM CV ??????  -->
<!-- **** MODS   identifier/@type  ====> DC identifier.other  **** -->
         <xsl:template match="*[local-name()='identifier']"> <!-- [@type='series']"> -->
                <xsl:element name="dim:field">
                <xsl:attribute name="mdschema">dc</xsl:attribute>
                <xsl:attribute name="element">identifier</xsl:attribute>
                <xsl:choose>
                    <xsl:when test="./@type='local'">
                            <xsl:attribute name="qualifier">other</xsl:attribute>
                    </xsl:when>
                    <xsl:when test="./@type='uri'">
                            <xsl:attribute name="qualifier">uri</xsl:attribute>
                    </xsl:when>
                    <xsl:when test="./@type='wosuid'">
                            <xsl:attribute name="qualifier">wos</xsl:attribute>
                    </xsl:when>
                     <xsl:when test="./@type='doi' or ./@type='issn' or ./@type='eissn' or ./@type='isbn' or ./@type='sici' or ./@type='ismn' or ./@type='slug' or ./@type='govdoc'
                        or ./@type='arxiv' or ./@type='bibcode' or ./@type='eid' or ./@type='ethos' or ./@type='pmc' or ./@type='pmid' or ./@type='source-work-id'
                         or ./@type='urn' or ./@type='cienciaiul'  or ./@type='authenticusid'">
                            <xsl:attribute name="qualifier"><xsl:value-of select="./@type"/></xsl:attribute>
                    </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="qualifier">other</xsl:attribute>
                </xsl:otherwise>
                </xsl:choose>
                        <xsl:attribute name="lang">en_US</xsl:attribute>
                        <xsl:value-of select="normalize-space(.)"/>
                </xsl:element>    
        </xsl:template>






<!-- **** MODS   originInfo/publisher  ====> DC  publisher  **** -->
        <xsl:template match="*[local-name()='originInfo']/*[local-name()='publisher']">
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">publisher</xsl:attribute>                 
                        <xsl:attribute name="lang">en_US</xsl:attribute>
                        <xsl:value-of select="normalize-space(.)"/>
                </xsl:element>
        </xsl:template>


<!-- Changes needed - CV deposit -->

<!-- **** MODS   originInfo/publisher  ====> Degois publication Loaction **** Now OAIRE CITATION -->
        <xsl:template match="*[local-name()='originInfo']/*[local-name()='place']/*[local-name()='placeTerm']">
            <xsl:choose>
                <xsl:when test="./@type='text'">
                    <xsl:element name="dim:field">
                            <xsl:attribute name="mdschema">oaire</xsl:attribute>
                            <xsl:attribute name="element">citation</xsl:attribute> 
                            <xsl:attribute name="qualifier">conferencePlace</xsl:attribute>                
                            <xsl:attribute name="lang">en_US</xsl:attribute>
                            <xsl:value-of select="normalize-space(.)"/>
                    </xsl:element>
                </xsl:when>
              </xsl:choose>   
        </xsl:template>

         <!-- mapping language -->
         <xsl:template match="*[local-name()='language']/*[local-name()='languageTerm']">

                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">language</xsl:attribute>
                        <xsl:attribute name="qualifier">iso</xsl:attribute>
                        <xsl:attribute name="lang">por</xsl:attribute>
                        <xsl:value-of select="normalize-space(.)"/>
                </xsl:element>
        </xsl:template>

        <!-- mapping description version -->
         <xsl:template match="*[local-name()='note']">
                <xsl:choose>
                   <xsl:when test="./@type='source identifier' and ./@xlink:href='http://www.cienciavitae.pt'"> 
                         <xsl:element name="dim:field">
                                <xsl:attribute name="mdschema">rcaap</xsl:attribute>
                                <xsl:attribute name="element">cv</xsl:attribute>
                                <xsl:attribute name="qualifier">cienciaid</xsl:attribute>
                                <xsl:value-of select="normalize-space(.)"/>
                        </xsl:element>
                    </xsl:when>
                      <xsl:when test="./@type='source email'">
                        <xsl:element name="dim:field">
                                <xsl:attribute name="mdschema">rcaap</xsl:attribute>
                                <xsl:attribute name="element">contributor</xsl:attribute> 
                                <xsl:attribute name="qualifier">authoremail</xsl:attribute>                
                                <xsl:value-of select="normalize-space(.)"/>
                        </xsl:element>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:element name="dim:field">
                                <xsl:attribute name="mdschema">dc</xsl:attribute>
                                <xsl:attribute name="element">description</xsl:attribute>
                                <xsl:attribute name="qualifier">version</xsl:attribute>
                                <!--<xsl:attribute name="lang">por</xsl:attribute>-->
                                <xsl:value-of select="normalize-space(.)"/>
                        </xsl:element>
                    </xsl:otherwise>
                 </xsl:choose>
        </xsl:template>

<!-- **** VOLUME AND ISSE MAPPED ON DEGOIS FIELDS DC.DEGOIS.VOLUME|ISSUE - Now OAIRE CITATION-->
        <xsl:template match="*[local-name()='detail']"> 
            <xsl:choose>
                <xsl:when test="not(./@type='section')">
                    <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">oaire</xsl:attribute>
                        <xsl:attribute name="element">citation</xsl:attribute>
                        <xsl:attribute name="qualifier"><xsl:value-of select="./@type"/></xsl:attribute>                       
                        <xsl:attribute name="lang">en_US</xsl:attribute>
                        <xsl:value-of select="normalize-space(.)"/>
                    </xsl:element>
                </xsl:when>
            </xsl:choose>
        </xsl:template>

        <!-- GET PAGES - THIS OR SEPARATE INDIVIDUALLY ????  DC.DEGOIS.FIRSTPAGE  ... DC:DEGOIS:LASTPAGE Now OAIRE CITATION -->
        <xsl:template match="*[local-name()='extent']"> 
               <xsl:choose>
                   <xsl:when test="./@unit='pages'"> 
                        <xsl:for-each select="./*">
                            <xsl:element name="dim:field">
                                <xsl:attribute name="mdschema">oaire</xsl:attribute>
                                <xsl:attribute name="element">citation</xsl:attribute>
                                <xsl:choose>
                                    <xsl:when test="contains(local-name(),'start')">
                                        <xsl:attribute name="qualifier">startPage</xsl:attribute>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:attribute name="qualifier">endPage</xsl:attribute>
                                    </xsl:otherwise>
                                </xsl:choose> 
                                <xsl:value-of select="normalize-space(.)"/>     
                            </xsl:element>
                        </xsl:for-each>   
                </xsl:when>
             </xsl:choose>                                     
        </xsl:template>

        <!-- **** LOCATION MAPPED ON DEGOIS FIELDS DC.DEGOIS.VOLUME|ISSUE Now OAIRE CITATION-->
        <!--<xsl:template match="*[local-name()='location']"> 
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">degois</xsl:attribute>
                        <xsl:attribute name="element">publication</xsl:attribute>
                        <xsl:attribute name="qualifier">location</xsl:attribute>                       
                        <xsl:attribute name="lang">en_US</xsl:attribute>
                        <xsl:value-of select="normalize-space(.)"/>
                </xsl:element>
        </xsl:template>-->

         <!-- **** DC TYPE-->
        <!--<xsl:template match="*[local-name()='genre']"> 
                <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">type</xsl:attribute>                      
                        <xsl:attribute name="lang">en_US</xsl:attribute>
                        <xsl:value-of select="normalize-space(.)"/>
                </xsl:element>
        </xsl:template>-->

        <xsl:template match="*[local-name()='genre']"> 
                 <xsl:call-template name="dcType">
                        </xsl:call-template>
        </xsl:template>


        <!-- mapping rights and embargoed access MISSING EMBARGOED DATE -->
         <xsl:template match="*[local-name()='accessCondition']">
            <xsl:choose>                                                                                                                                                        
                <xsl:when test="@xlink:href='info:eu-repo/semantics/embargoedAccess'">
                    <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">rights</xsl:attribute>
                        <xsl:attribute name="lang">en_US</xsl:attribute>
                        <xsl:text>embargoedAccess</xsl:text>
                        <xsl:value-of select="normalize-space(.)"/>
                    </xsl:element>     
                    <xsl:call-template name="dateEmbargo">
                        <xsl:with-param name="dateEmbargo" select="../*[local-name()='originInfo']/*[local-name()='copyrightDate' and @point='end']" />
                    </xsl:call-template>
                </xsl:when>      
                 <xsl:when test="@xlink:href='info:eu-repo/semantics/closedAccess'">
                    <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">rights</xsl:attribute>
                        <xsl:attribute name="lang">en_US</xsl:attribute>
                        <xsl:text>closedAccess</xsl:text> 
                    </xsl:element>
                </xsl:when>               
                <xsl:when test="@xlink:href='info:eu-repo/semantics/restrictedAccess'">
                    <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">rights</xsl:attribute> 
                        <xsl:attribute name="lang">en_US</xsl:attribute>
                        <xsl:text>restrictedAccess</xsl:text>
                    </xsl:element>           
                </xsl:when>   
                <xsl:otherwise>
                    <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">rights</xsl:attribute>
                        <xsl:attribute name="lang">en_US</xsl:attribute>
                        <xsl:text>openAccess</xsl:text>
                    </xsl:element>       
                </xsl:otherwise>                                                                                 
            </xsl:choose>
        </xsl:template>
        
    <xsl:template name="dateEmbargo">
            <xsl:param name="dateEmbargo" />
            <xsl:element name="dim:field">
                        <xsl:attribute name="mdschema">dc</xsl:attribute>
                        <xsl:attribute name="element">date</xsl:attribute>
                        <xsl:attribute name="qualifier">embargo</xsl:attribute> 
                        <xsl:value-of select="normalize-space($dateEmbargo)"/>
                    </xsl:element> 
        </xsl:template>

   <xsl:template name="dcType">
        <xsl:element name="dim:field">
                <xsl:attribute name="mdschema">dc</xsl:attribute>
                <xsl:attribute name="element">type</xsl:attribute>
                <xsl:attribute name="lang">en_US</xsl:attribute>
                <xsl:choose>
                        <xsl:when test="//*[text()='article']">
                                <xsl:text>article</xsl:text>
                        </xsl:when>
                        <xsl:when test="//*[text()='patent']">
                                <xsl:text>patent</xsl:text>
                        </xsl:when>
                        <xsl:when test="//*[text()='contributionToPeriodical']">
                                <xsl:text>contribution to periodical</xsl:text>
                        </xsl:when>
                        <xsl:when test="//*[text()='conferenceObject']">
                                <xsl:text>conference object</xsl:text>
                        </xsl:when>
                        <xsl:when test="//*[text()='lecture']">
                                <xsl:text>lecture</xsl:text>
                        </xsl:when>
                        <xsl:when test="//*[text()='review']">
                                <xsl:text>review</xsl:text>
                        </xsl:when>
                        <!-- Não existe no openaire????-->
                        <xsl:when test="//*[text()='pedagogicalEducation']">
                                <xsl:text>pedagogical education</xsl:text>
                        </xsl:when>
                        <xsl:when test="//*[text()='preprint']">
                                <xsl:text>preprint</xsl:text>
                        </xsl:when>
                        <xsl:when test="//*[text()='annotation']">
                                <xsl:text>annoatiob</xsl:text>
                        </xsl:when>
                        <xsl:when test="//*[text()='report']">
                                <xsl:text>report</xsl:text>
                        </xsl:when>
                        <xsl:when test="//*[text()='workingPaper']">
                                <xsl:text>working paper</xsl:text>
                        </xsl:when>
                        <xsl:when test="//*[text()='book']">
                                <xsl:text>book</xsl:text>
                        </xsl:when>
                        <xsl:when test="//*[text()='bookPart']">
                                <xsl:text>book part</xsl:text>
                        </xsl:when>
                        <xsl:when test="//*[text()='bachelorThesis']">
                                <xsl:text>bachelor thesis</xsl:text>
                        </xsl:when>      
                        <xsl:when test="//*[text()='doctoralThesis']">
                                <xsl:text>doctoral thesis</xsl:text>
                        </xsl:when>
                        <xsl:when test="//*[text()='masterThesis']">
                                <xsl:text>master thesis</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                                <xsl:text>other</xsl:text>
                        </xsl:otherwise>
                </xsl:choose>                      
            </xsl:element>
        </xsl:template>

</xsl:stylesheet>
