package org.dspace.ctask.general;

import org.apache.logging.log4j.Logger;
import org.dspace.content.Item;
import org.dspace.curate.Distributive;

import java.io.IOException;
import java.sql.SQLException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Distributive
public class DoiValidator extends Distribute {
    private static Logger log = org.apache.logging.log4j.LogManager.getLogger(DoiValidator.class);

    private static String ITEM_DOI = "dc.identifier.doi";
    private static String DOI_PREFIX = "https?://(?:(dx\\.)?)doi\\.org/";

    //FROM CROSS REF https://www.crossref.org/blog/dois-and-matching-regular-expressions/
    /*
    *
    * ^10.\d{4,9}/[-._;()/:A-Z0-9]+$
    * ^10.1002/[^\s]+$
    *
    * ^10.\d{4}/\d+-\d+X?(\d+)\d+<[\d\w]+:[\d\w]*>\d+.\d+.\w+;\d$
    * ^10.1021/\w\w\d++$
    * ^10.1207/[\w\d]+\&\d+_\d+$
    *
     */
    //Other regular expressions
    private static String DOI_EXPRESSION1 = "^10\\.\\d{4,9}/[-\\._;()/:a-zA-Z0-9]+$";
    private static String DOI_EXPRESSION2 = "^10\\.1002/[^\\s]+$";
    private static String DOI_EXPRESSION3 = "^10\\.\\d{4}/\\d+-\\d+X?(\\d+)\\d+<[\\d\\w]+:[\\d\\w]*>\\d+\\.\\d+\\.\\w+;\\d$";
    private static String DOI_EXPRESSION4 = "^10\\.1021/\\w\\w\\d++$";
    private static String DOI_EXPRESSION5 = "^10\\.1207/[\\w\\d]+\\&\\d+_\\d+$";



    /***
     *
     * @param item
     * @throws SQLException
     * @throws IOException
     */
    @Override
    protected void performItem(Item item) throws SQLException, IOException {

        String doi = itemService.getMetadata(item, ITEM_DOI);

        if(doi != null && doi.length()>0){
            String handle = item.getHandle();

            doi = doi.trim();
            Pattern p = Pattern.compile(DOI_PREFIX, Pattern.CASE_INSENSITIVE);
            Matcher m = p.matcher(doi);
            doi = m.replaceAll("");

            if (!doi.matches(DOI_EXPRESSION1) && !doi.matches(DOI_EXPRESSION2) &&
                    !doi.matches(DOI_EXPRESSION3) && !doi.matches(DOI_EXPRESSION4) &&
                    !doi.matches(DOI_EXPRESSION5)) {
                res.append("\t\t\thttp://hdl.handle.net/");
                res.append(handle);
                res.append(" pode ter um DOI inválido \n");
            }
        }

    }
}
