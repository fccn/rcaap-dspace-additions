package org.dspace.external.provider.impl;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.math3.analysis.function.Add;
import org.apache.logging.log4j.Logger;
import org.dspace.content.dto.MetadataValueDTO;
import org.dspace.external.OpenAIRERestConnector;
import org.dspace.external.model.ExternalDataObject;
import org.dspace.external.provider.AbstractExternalDataProvider;
import org.springframework.beans.factory.annotation.Autowired;
import pt.cienciavitae.ns.author_identifier.AuthorIdentifier;
import pt.cienciavitae.ns.citation_name.CitationName;
import pt.cienciavitae.ns.common_enum.PrivacyLevelEnum;
import pt.cienciavitae.ns.curriculum.Curriculum;
import pt.cienciavitae.ns.person.Person;
import pt.cienciavitae.ns.search.Search;
import pt.rcaap.cienciavitae.curriculum.client.CienciaVitaeUtils;
import pt.rcaap.cienciavitae.curriculum.client.ClientException;
import pt.rcaap.cienciavitae.curriculum.client.CurriculumRestClient;
import pt.rcaap.cienciavitae.curriculum.client.RestConnector;
import pt.rcaap.cienciavitae.curriculum.client.SearchRestClient;

public class CienciaVitaeCurriculumDataProvider extends AbstractExternalDataProvider {
    /**
     * Source identifier (defined in beans)
     */
    protected String sourceIdentifier;

    /**
     * log4j logger
     */
    private static Logger log = org.apache.logging.log4j.LogManager.getLogger(CienciaVitaeCurriculumDataProvider.class);

    protected RestConnector connector;

    private static String cienciaVitaeUrl;

    private static final String AUTHENTICUS_ID_PREFIX = "urn:authenticus_id:";

    /**
     * required method
     */
    public void init() throws IOException {
    }

    /**
     * Generic setter for RestConnector
     * 
     * @param connector
     */
    @Autowired(required = true)
    public void setConnector(RestConnector connector) {
        this.connector = connector;
    }

    public RestConnector getConnector() {
        return connector;
    }

    /**
     * Generic setter for the sourceIdentifier
     * 
     * @param sourceIdentifier
     */
    @Autowired(required = true)
    public void setSourceIdentifier(String sourceIdentifier) {
        this.sourceIdentifier = sourceIdentifier;
    }

    @Override
    public String getSourceIdentifier() {
        return sourceIdentifier;
    }

    /**
     * Generic getter for the orcidUrl
     * 
     * @return the orcidUrl value of this OrcidV3AuthorDataProvider
     */
    public String getCienciaVitaeUrl() {
        return cienciaVitaeUrl;
    }

    /**
     * Generic setter for the orcidUrl
     * 
     * @param orcidUrl The orcidUrl to be set on this OrcidV3AuthorDataProvider
     */
    @Autowired(required = true)
    public void setCienciaVitaeUrl(String cienciaVitaeUrl) {
        this.cienciaVitaeUrl = cienciaVitaeUrl;
    }

    @Override
    public Optional<ExternalDataObject> getExternalDataObject(String id) {
        if (connector == null) {
            log.error("CienciaVitae connector is required, null found");
            return Optional.empty();
        }

        ExternalDataObjectBuilder builder = null;
        if (CienciaVitaeUtils.isValidCienciaID(id)) {
            // search by ciencia-id
            CurriculumRestClient restClient = new CurriculumRestClient(connector);
            try {
                Curriculum result = restClient.getCurriculumByCID(id, null);

                if (result == null) {
                    return Optional.empty();
                }

                builder = new CienciaVitaeCurriculumDataProvider.ExternalDataObjectBuilder(result);
            } catch (ClientException e) {
                log.error("Invalid CienciaVitae result - " + e.getMessage());
            }

        } else {
            // use search
            SearchRestClient searchPerson = new SearchRestClient(connector);
            try {
                // search person by id (first row)
                Search result = searchPerson.searchPerson(id, true, null, 1, 1, 0, null);

                if (result == null && result.getTotal() > 0) {
                    return Optional.empty();
                }

                builder = new CienciaVitaeCurriculumDataProvider.ExternalDataObjectBuilder(
                        result.getResult().getPerson().get(0));
            } catch (ClientException e) {
                log.error("Invalid CienciaVitae result - " + e.getMessage());
            }
        }

        if (builder != null) {
            return Optional.of(builder.setSource(sourceIdentifier).setId(id).setValue(id).build());
        }
        return Optional.empty();
    }

    @Override
    public boolean supports(String source) {
        return StringUtils.equalsIgnoreCase(sourceIdentifier, source);
    }

    @Override
    public int getNumberOfResults(String query) {
        // escaping query
        SearchRestClient restClient = new SearchRestClient(connector);
        try {
            Search response = restClient.searchPerson(query, false, null, 1, 0, 0, null);
            return response.getTotal();
        } catch (ClientException e) {
            log.error("Invalid CienciaVitae get total results - " + e.getMessage());
        }
        return 0;
    }

    @Override
    public List<ExternalDataObject> searchExternalDataObjects(String query, int start, int rows) {

        // ensure we have a positive > 0 limit
        if (rows < 1) {
            rows = 10;
        }

        // first page starts with 1
        int page = (start / rows) + 1;

        SearchRestClient restClient = new SearchRestClient(connector);
        try {
            Search response = restClient.searchPerson(query, true, null, rows, page, 0, null);

            if (response == null || response.getTotal() == null) {
                return Collections.emptyList();
            }

            if (response.getTotal() > 0) {
                return response.getResult().getPerson().stream()
                        .map(person -> new CienciaVitaeCurriculumDataProvider.ExternalDataObjectBuilder(person)
                                .setSource(sourceIdentifier).build())
                        .collect(Collectors.toList());
            }
        } catch (ClientException e) {
            log.error("Invalid CienciaVitae search results - " + e.getMessage());
        }
        return Collections.emptyList();
    }

    /**
     * CienciaViate Person External Data Builder Class
     * 
     * @author pgraca
     *
     */
    public static class ExternalDataObjectBuilder {
        ExternalDataObject externalDataObject;

        public ExternalDataObjectBuilder() {
            externalDataObject = new ExternalDataObject();
        }

        public ExternalDataObjectBuilder(Person person) {
            externalDataObject = new ExternalDataObject();
            String orcidID = null;
            String cienciaID = null;

            for (AuthorIdentifier identifier : person.getAuthorIdentifiers().getAuthorIdentifier()) {
                switch (identifier.getIdentifierType().getCode()) {
                    case AUTHENTICUSID:
                        if (identifier.getPrivacyLevel() == PrivacyLevelEnum.PUBLICO) {
                            this.addOtherIdentifier(AUTHENTICUS_ID_PREFIX + identifier.getIdentifier());
                        }
                        break;
                    case CIENCIAID:
                        if (identifier.getPrivacyLevel() == PrivacyLevelEnum.PUBLICO) {
                            cienciaID = identifier.getIdentifier();
                            this.addCienciaId(cienciaID);
                            this.addIdentifierURI(cienciaID);
                        }
                        break;
                    case GOOGLE:
                        if (identifier.getPrivacyLevel() == PrivacyLevelEnum.PUBLICO) {
                            this.addGoogleScholarId(identifier.getIdentifier());
                        }
                        break;
                    case ORCID:
                        if (identifier.getPrivacyLevel() == PrivacyLevelEnum.PUBLICO) {
                            orcidID = identifier.getIdentifier();
                            this.addOrcidId(orcidID);
                        }
                        break;
                    case SCOPUS:
                        if (identifier.getPrivacyLevel() == PrivacyLevelEnum.PUBLICO) {
                            this.addScopusAuthorId(identifier.getIdentifier());
                        }
                        break;
                    case WOS:
                        if (identifier.getPrivacyLevel() == PrivacyLevelEnum.PUBLICO) {
                            this.addWoSResearcherId(identifier.getIdentifier());
                        }
                        break;
                    default:
                        if (identifier.getPrivacyLevel() == PrivacyLevelEnum.PUBLICO) {
                            this.addOtherIdentifier(identifier.getIdentifier());
                        }
                        break;

                }
            }

            String name = person.getPersonInfo().getPresentedName();
            if (person.getCitationNames().getTotal() > 0) {
                // Get the preferred citation name
                for (CitationName citationName : person.getCitationNames().getCitationName()) {
                    if (citationName.getPrivacyLevel() == PrivacyLevelEnum.PUBLICO
                            && citationName.isPreferredCitationName()) {
                        name = citationName.getValue();
                    }
                }
            }
            if (name == null) {
                name = person.getPersonInfo().getFullName();
            }

            this.addGivenName(person.getPersonInfo().getNames()).addFamilyName(person.getPersonInfo().getSurnames())
                    .setDisplayValue(name).addName(name).addAltName(person.getPersonInfo().getFullName());

            // give priority to orcid identifier (if one exists)
            if (orcidID != null) {
                this.setId(orcidID).setValue(orcidID);
            } else {
                this.setId(cienciaID).setValue(cienciaID);
            }

        }

        public ExternalDataObjectBuilder(Curriculum person) {
            externalDataObject = new ExternalDataObject();
            String orcidID = null;
            String cienciaID = null;

            for (AuthorIdentifier identifier : person.getIdentifyingInfo().getAuthorIdentifiers()
                    .getAuthorIdentifier()) {
                switch (identifier.getIdentifierType().getCode()) {
                    case AUTHENTICUSID:
                        if (identifier.getPrivacyLevel() == PrivacyLevelEnum.PUBLICO) {
                            this.addOtherIdentifier(AUTHENTICUS_ID_PREFIX + identifier.getIdentifier());
                        }
                        break;
                    case CIENCIAID:
                        if (identifier.getPrivacyLevel() == PrivacyLevelEnum.PUBLICO) {
                            cienciaID = identifier.getIdentifier();
                            this.addCienciaId(cienciaID);
                            this.addIdentifierURI(cienciaID);
                        }
                        break;
                    case GOOGLE:
                        if (identifier.getPrivacyLevel() == PrivacyLevelEnum.PUBLICO) {
                            this.addGoogleScholarId(identifier.getIdentifier());
                        }
                        break;
                    case ORCID:
                        if (identifier.getPrivacyLevel() == PrivacyLevelEnum.PUBLICO) {
                            orcidID = identifier.getIdentifier();
                            this.addOrcidId(orcidID);
                        }
                        break;
                    case SCOPUS:
                        if (identifier.getPrivacyLevel() == PrivacyLevelEnum.PUBLICO) {
                            this.addScopusAuthorId(identifier.getIdentifier());
                        }
                        break;
                    case WOS:
                        if (identifier.getPrivacyLevel() == PrivacyLevelEnum.PUBLICO) {
                            this.addWoSResearcherId(identifier.getIdentifier());
                        }
                        break;
                    default:
                        if (identifier.getPrivacyLevel() == PrivacyLevelEnum.PUBLICO) {
                            this.addOtherIdentifier(identifier.getIdentifier());
                        }
                        break;

                }
            }

            String name = person.getIdentifyingInfo().getPersonInfo().getPresentedName();
            if (person.getIdentifyingInfo().getCitationNames().getTotal() > 0) {
                // Get the preferred citation name
                for (CitationName citationName : person.getIdentifyingInfo().getCitationNames().getCitationName()) {
                    if (citationName.getPrivacyLevel() == PrivacyLevelEnum.PUBLICO
                            && citationName.isPreferredCitationName()) {
                        name = citationName.getValue();
                    }
                }
            }
            // Set name as full name as a default
            if (name == null) {
                name = person.getIdentifyingInfo().getPersonInfo().getFullName();
            }

            this.addGivenName(person.getIdentifyingInfo().getPersonInfo().getNames())
                    .addFamilyName(person.getIdentifyingInfo().getPersonInfo().getSurnames()).setDisplayValue(name)
                    .addName(name).addAltName(person.getIdentifyingInfo().getPersonInfo().getFullName());

        }

        /**
         * Set the external data source
         * 
         * @param source
         * @return ExternalDataObjectBuilder
         */
        public ExternalDataObjectBuilder setSource(String source) {
            this.externalDataObject.setSource(source);
            return this;
        }

        /**
         * Set the external data display name
         * 
         * @param displayName
         * @return ExternalDataObjectBuilder
         */
        public ExternalDataObjectBuilder setDisplayValue(String displayName) {
            this.externalDataObject.setDisplayValue(displayName);
            return this;
        }

        /**
         * Set the external data value
         * 
         * @param value
         * @return ExternalDataObjectBuilder
         */
        public ExternalDataObjectBuilder setValue(String value) {
            this.externalDataObject.setValue(value);
            return this;
        }

        /**
         * Set the external data id
         * 
         * @param id
         * @return ExternalDataObjectBuilder
         */
        public ExternalDataObjectBuilder setId(String id) {
            this.externalDataObject.setId(id);
            return this;
        }

        public ExternalDataObjectBuilder addOrcidId(String orcid) {
            this.externalDataObject.addMetadata(new MetadataValueDTO("person", "identifier", "orcid", null, orcid));
            return this;
        }

        public ExternalDataObjectBuilder addCienciaId(String cienciaId) {
            this.externalDataObject
                    .addMetadata(new MetadataValueDTO("person", "identifier", "ciencia-id", null, cienciaId));
            return this;
        }

        public ExternalDataObjectBuilder addScopusAuthorId(String scopusAuthorId) {
            this.externalDataObject.addMetadata(
                    new MetadataValueDTO("person", "identifier", "scopus-author-id", null, scopusAuthorId));
            return this;
        }

        public ExternalDataObjectBuilder addWoSResearcherId(String rid) {
            this.externalDataObject.addMetadata(new MetadataValueDTO("person", "identifier", "rid", null, rid));
            return this;
        }

        public ExternalDataObjectBuilder addGoogleScholarId(String googleScholarId) {
            this.externalDataObject
                    .addMetadata(new MetadataValueDTO("person", "identifier", "gsid", null, googleScholarId));
            return this;
        }

        public ExternalDataObjectBuilder addIdentifierURI(String identifier) {
            this.externalDataObject.addMetadata(
                    new MetadataValueDTO("dc", "identifier", "uri", null, cienciaVitaeUrl + "/" + identifier));
            return this;
        }

        public ExternalDataObjectBuilder addOtherIdentifier(String identifier) {
            this.externalDataObject.addMetadata(new MetadataValueDTO("person", "identifier", null, null, identifier));
            return this;
        }

        public ExternalDataObjectBuilder addGivenName(String givenName) {
            this.externalDataObject.addMetadata(new MetadataValueDTO("person", "givenName", null, null, givenName));
            return this;
        }

        public ExternalDataObjectBuilder addFamilyName(String familyName) {
            this.externalDataObject.addMetadata(new MetadataValueDTO("person", "familyName", null, null, familyName));
            return this;
        }

        public ExternalDataObjectBuilder addName(String name) {
            this.externalDataObject.addMetadata(new MetadataValueDTO("dc", "title", null, null, name));
            return this;
        }

        /**
         * Add an alternative name
         * 
         * @param name
         * @return
         */
        public ExternalDataObjectBuilder addAltName(String name) {
            this.externalDataObject.addMetadata(new MetadataValueDTO("dc", "title", "alternative", null, name));
            return this;
        }

        /**
         * Build the External Data
         * 
         * @return ExternalDataObject
         */
        public ExternalDataObject build() {
            return this.externalDataObject;
        }
    }
}
