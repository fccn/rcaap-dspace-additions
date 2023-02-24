package org.dspace.external.provider.impl;


import org.apache.commons.lang3.StringUtils;
import org.apache.logging.log4j.Logger;
import org.dspace.content.dto.MetadataValueDTO;
import org.dspace.external.RenatesConnector;
import org.dspace.external.model.ExternalDataObject;
import org.dspace.external.provider.AbstractExternalDataProvider;
//import org.jaxen.JaxenException;
import org.springframework.beans.factory.annotation.Autowired;

import java.io.IOException;
import java.io.InputStream;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import org.jdom2.Document;
import org.jdom2.Element;
import org.jdom2.JDOMException;
import org.jdom2.filter.Filters;
import org.jdom2.input.SAXBuilder;
import org.jdom2.xpath.XPathExpression;
import org.jdom2.xpath.XPathFactory;


public class RenatesLiveImporter extends AbstractExternalDataProvider {

    protected String sourceIdentifier;
    protected RenatesConnector renatesConnector;
    protected String tidRegExp;
    protected HashMap<String, String> tipoTese;

    private static Logger log = org.apache.logging.log4j.LogManager.getLogger(RenatesLiveImporter.class);


    /**
     * Generic setter for RenatesConnector
     *
     * @param renatesConnector
     */
    @Autowired(required = true)
    public void setRenatesConnector(RenatesConnector renatesConnector) {
        this.renatesConnector = renatesConnector;
    }


    @Override
    public String getSourceIdentifier() {
        return sourceIdentifier;
    }

    /**
     *
     * @param id    The id on which will be searched - Renates
     * @return The metadata to include in the input-forms
     */
	@Override
    public Optional<ExternalDataObject> getExternalDataObject(String id) {
        
		InputStream result = renatesConnector.getRenatesData(id, 0, 0);
        SAXBuilder builder = new SAXBuilder();
        Document document = null;
     
        try {
			
			document = builder.build(result);
			
			XPathFactory xpfac = XPathFactory.instance();
            XPathExpression<Element> elements = xpfac.compile("//Tese/Tese", Filters.element());
            List<Element> teseElements = elements.evaluate(document);


            //This one has the data per se if we don't use extends Abstract...
            if(teseElements.size() > 0) {
                //There is only one record
				Element tese = elements.evaluate(document).get(0);
                return getRenatesExternalDataObject(tese).stream().findFirst();
                //return Optional.of(getRenatesExternalDataObject(elements).stream().findFirst().get());
            }

        } catch (JDOMException | IOException e) {
            //log.debug(e.printStackTrace());
			e.printStackTrace();
        }
        return Optional.empty();
    }
	 
    
	@Override
    public List<ExternalDataObject> searchExternalDataObjects(String query, int start, int limit) {
        
		log.info("Quering Renates to get the Thesis identified by " + query.trim());
        
		query = query.trim();
        Pattern pattern = Pattern.compile(tidRegExp);
        Matcher matcher = pattern.matcher(query);
        if(!matcher.find()){
            log.debug("The search query doesn't match TID Criteria");
            throw new RuntimeException("The search query doesn't match TID Criteria");
        }
		
		InputStream result = renatesConnector.getRenatesData(query, 0, 0);
        SAXBuilder builder = new SAXBuilder();
        Document document = null;
     
        try {
			
			document = builder.build(result);
			
			XPathFactory xpfac = XPathFactory.instance();
            XPathExpression<Element> elements = xpfac.compile("//Tese/Tese", Filters.element());
            List<Element> teseElements = elements.evaluate(document);


            //This one has the data per se if we don't use extends Abstract...
            if(teseElements.size() > 0) {
                //There is only one record
				Element tese = elements.evaluate(document).get(0);
                return getRenatesExternalDataObject(tese).stream().collect(Collectors.toList());
            }

        } catch (JDOMException | IOException e) {
			//log.debug(e.printStackTrace());
			e.printStackTrace();
        }
		
        return Collections.emptyList();
		
    }
	

    @Override
    public boolean supports(String source) {
        return StringUtils.equalsIgnoreCase(sourceIdentifier, source);
    }

    @Override
    public int getNumberOfResults(String query) {
        //Should return 1 if exists - But it return on maximum 1
        //Call API RENATES...????
        return 1;
    }

    /**
     * Generic setter for the sourceIdentifier
     *
     * @param sourceIdentifier The sourceIdentifier to be set on this
     *                         OpenAIREFunderDataProvider
     */
    @Autowired(required = true)
    public void setSourceIdentifier(String sourceIdentifier) {
        this.sourceIdentifier = sourceIdentifier;
    }

    /**
     * Generic setter for the tidRegExp
     *
     * @param tidRegExp
     *
     */
    @Autowired(required = true)
    public void setTidRegExp(String tidRegExp) {
        this.tidRegExp = tidRegExp;
    }

    /**
     * Generic setter for the tipoTese
     *
     * @param tipoTese
     *
     */
    @Autowired(required = true)
    public void setTipoTese(HashMap<String, String> tipoTese) {
        this.tipoTese = tipoTese;
    }

    /**
     * Initialize the accessToken that is required for all subsequent calls to ORCID.
     *
     * @throws java.io.IOException passed through from HTTPclient.
     */
    public void init() throws IOException {
        //can be used to get token or to initialize other things
    }

	/**
     *
     * @param elements data form DGEEC API - element tese
     * @return the list of 1 result if exists
	 * Using to JDOM2 as Axiom is deprecated in DSpace
    */
	private Collection<ExternalDataObject> getRenatesExternalDataObject(Element tese){
			
		List<ExternalDataObject> records = new LinkedList<ExternalDataObject>();
        ExternalDataObject externalDataObject = new ExternalDataObject(sourceIdentifier);
			
		String tid = tese.getChildren("TID").get(0).getText().trim();
		String title = tese.getChildren("TemaTese").get(0).getText().trim();
		String author = tese.getChildren("NomeCompleto").get(0).getText().trim();
		if(author.lastIndexOf(" ") > 0){
			author = author.substring(author.lastIndexOf(" ")+1) + ", " + author.substring(0, author.lastIndexOf(" "));
		}

		String type = (tese.getChildren("TipoTese").get(0).getText()).equalsIgnoreCase("mestrado")  ? "master thesis" : "doctoral thesis";
		
		externalDataObject.addMetadata(new MetadataValueDTO("dc","identifier","tid","",tid));
		externalDataObject.addMetadata(new MetadataValueDTO("dc","title",null, "",title));
		externalDataObject.addMetadata(new MetadataValueDTO("dc","type",null, "", type));
		externalDataObject.addMetadata(new MetadataValueDTO("dc","contributor","author", "", author));
		
		
		try {
			
			String dateIssued = tese.getChildren("DataGrau").get(0).getText().trim();
			if(dateIssued != null ){
				StringBuilder sb = new StringBuilder();
				java.lang.String dates[] = dateIssued.split("-");
				if(dates.length > 2)
					dateIssued = sb.append(dates[2]).append("-").append(dates[1]).append("-").append(dates[0]).toString();
				else
					dateIssued = dates.length > 1 ? sb.append(dates[1]).append("-").append(dates[0]).toString() : dateIssued;
			}
			
			externalDataObject.addMetadata(new MetadataValueDTO("dc","date","issued", "", dateIssued));
			
			
			String keywords = tese.getChildren("Palavras_chave").get(0).getText();
			if (keywords != null) {
				String[] subjects = keywords.split("[,;]");
				if (subjects.length > 0) {
					for (String subject : subjects) {
						externalDataObject.addMetadata(new MetadataValueDTO("dc","subject", null,"", subject.trim()));
					}
				} else
				   externalDataObject.addMetadata(new MetadataValueDTO("dc","subject",null, "", keywords.trim()));
				}
		}
		catch(Exception e){
			//Do nothing;
		}

		//Other way to do the thing is to comppile for every Element...
		//XPathExpression<Element> el = xpfac.compile("//Tese/Tese/TID", Filters.element());
		//Element e = el.evaluate(document).get(0);
		
		externalDataObject.setId(tid);
		externalDataObject.setDisplayValue(title);
		externalDataObject.setValue(title);

		records.add(externalDataObject);
		return records;

    }   

}
