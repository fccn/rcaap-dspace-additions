package org.dspace.ctask.general;

import org.apache.logging.log4j.Logger;
import org.dspace.content.*;
import org.dspace.content.Collection;
import org.dspace.content.factory.ContentServiceFactory;
import org.dspace.content.service.BitstreamFormatService;
import org.dspace.core.Constants;
import org.dspace.curate.AbstractCurationTask;
import org.dspace.curate.Curator;
import org.dspace.curate.Distributive;

import java.io.IOException;
import java.sql.SQLException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.*;

@Distributive
public class VerifyTID extends Distribute {

    private static Logger log = org.apache.logging.log4j.LogManager.getLogger(VerifyTID.class);
    private static String THESIS_DATE = "2013-08-07";
    private static String COARTYPE_DOCTORAL = "c_db06";
    private static String COARTYPE_MASTER = "c_bdcc";

    @Override
    protected void performItem(Item item) throws SQLException, IOException {

        String type = itemService.getMetadata(item,"dc.type");
        
        //Just in case there is no dc.type
        if(type != null){
            
            type = type.toLowerCase().replaceAll("\\s","");

            if (type.equals("masterthesis") || type.equals("doctoralthesis") ||
                    type.contains(COARTYPE_MASTER) || type.contains(COARTYPE_DOCTORAL)) {
                String tid = itemService.getMetadata(item,"dc.identifier.tid");
                String strIssuedDate = itemService.getMetadata(item,"dc.date.issued");
                String handle = item.getHandle();
                 if (strIssuedDate != null) {
                     if(verifyIssueDateAfter(strIssuedDate) && (tid == null || tid.isEmpty())) {
                         if (item.isArchived() && !item.isWithdrawn()) {
                             res.append("\t\thttp://hdl.handle.net/");
                             res.append(handle);
                             res.append(" - não tem TID \n");
                         }
                     }
                }
                 else{
                     res.append("\t\thttp://hdl.handle.net/");
                     res.append(handle);
                     res.append(" - Sem dateIssued - Inconclusivo\n");
                 }
            }
        }
    }

    /***
     *
     * @param strIssuedDate - A String with the issued date
     * @return true if the issue date is superior to 2013-08-07
     */
    private boolean verifyIssueDateAfter(String strIssuedDate){

        List<SimpleDateFormat> knownPatterns = new ArrayList<SimpleDateFormat>();
        knownPatterns.add(new SimpleDateFormat("yyyy-MM-dd"));
        knownPatterns.add(new SimpleDateFormat("yyyy-MM"));
        knownPatterns.add(new SimpleDateFormat("yyyy"));

        //int result = -1;
        boolean isAfter = false;

        Date dateIsued = null;
        Date thesisDate = null;
        try {
            thesisDate = new SimpleDateFormat("yyyy-MM-dd").parse(THESIS_DATE);
        }catch (ParseException pe) {
            log.info("Error parsing dateIssued to Known format: " + pe);
            return false;
        }

        for (SimpleDateFormat pattern : knownPatterns) {
            try {
                // Take a try
                dateIsued = new Date(pattern.parse(strIssuedDate).getTime());
                //result = dateIsued.compareTo(thesisDate);
                if ((isAfter = dateIsued.after(thesisDate))) {
                    break;
                }
            } catch (ParseException pe) {
                //log.info("Error parsing dateIssued to Known format: " + pe);
                //do nothing
            }
        }

        return isAfter;
    }

    private void formatResults() throws IOException {
        report(res.toString());
        setResult(res.toString());

    }

}
