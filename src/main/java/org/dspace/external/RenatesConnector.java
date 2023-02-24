package org.dspace.external;

import org.apache.http.*;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.utils.URIBuilder;
import org.apache.http.impl.client.HttpClientBuilder;
import org.apache.logging.log4j.Logger;
import org.dspace.external.provider.impl.RenatesLiveImporter;

import java.io.IOException;
import java.io.InputStream;
import java.net.URISyntaxException;

public class RenatesConnector {

    /*
     * No need to define this in xml - It doesn't change the renates identifier
     */
    private static String QUERYPARAM = "tid";
    protected String renatesURI;

    private static Logger log = org.apache.logging.log4j.LogManager.getLogger(RenatesConnector.class);

    /**
     *
     * Actual method to get the data from Renates
     *
     * @param query the TID identifier
     * @param start if pages exists this is the start value to get the next page
     * @param limit the number of results to retrieve from the search
     * @return
     */
    public InputStream getRenatesData(String query, int start, int limit) {
        HttpGet method;

        InputStream result = null;
        try {
            HttpClient client = HttpClientBuilder.create().build();
            URIBuilder uriBuilder = new URIBuilder(renatesURI);
            uriBuilder.addParameter(QUERYPARAM, query);
            method = new HttpGet(uriBuilder.build());

            HttpResponse response = client.execute(method);

            StatusLine responseStatus = response.getStatusLine();
            // registering errors
            switch (responseStatus.getStatusCode()) {
                case HttpStatus.SC_NOT_FOUND:
                    // 404 - Not found
                    log.error("HTTP Status Code: " + responseStatus);
                case HttpStatus.SC_FORBIDDEN:
                    // 403 - Invalid Access Token
                    log.error("HTTP Status Code: " + responseStatus);
                case 429:
                    // 429 - Rate limit abuse for unauthenticated user
                    // 429 - Rate limit abuse
                    log.error("HTTP Status Code: " + responseStatus);
                    break;
            }

            // do not close this httpClient
            result = response.getEntity().getContent();


        } catch (URISyntaxException e) {
            log.error("URISyntaxException: " + e);
        } catch (ClientProtocolException e) {
            log.error("ClientProtocolException: " + e);
        } catch (IOException e) {
            log.error("IOException: " + e);
        }

        return result;
    }

    /**
     *
     * @param renatesURI defined in xml the setter needed to Spring inject the URL parameter
     */
    public void setRenatesURI(String renatesURI) {
        this.renatesURI = renatesURI;
    }
}
