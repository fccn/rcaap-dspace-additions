package org.dspace.ctask.general;

import org.apache.logging.log4j.Logger;
import org.dspace.content.Item;
import org.dspace.curate.Curator;
import org.dspace.curate.Distributive;

import java.io.IOException;
import java.sql.SQLException;

@Distributive
public class EmbargoJustification extends Distribute {
    private static Logger log = org.apache.logging.log4j.LogManager.getLogger(EmbargoJustification.class);

    private String RIGHTS = "dc.rights";
    private String RELATION = "dc.relation";
    private String EMBARGO_FCT = "rcaap.embargofct";

    private String OPEN_ACCESS = "openAccess";

    @Override
    protected void performItem(Item item) throws SQLException, IOException {
        String handle = item.getHandle();
        String rights = itemService.getMetadata(item, RIGHTS);
        String relation = itemService.getMetadata(item, RELATION);
        String justification = itemService.getMetadata(item, EMBARGO_FCT);

        //String Item_UUID = item.getID().toString();
        //itemService.getEntityType(Curator.curationContext(), item).toString();
        if(item.isArchived() && !item.isWithdrawn())
            /*if( relation != null && relation.length()> 0 &&
                    rights != null && !OPEN_ACCESS.equals(rights) &&
                    (justification == null || justification.isEmpty()) ){

                res.append("\t\t\thttp://hdl.handle.net/");
                res.append(handle);
                res.append(" não tem justificação para o embargo.");
                res.append(" with rights: ");
                res.append(rights);
                res.append("\n");
            }*/
            if( rights != null && !OPEN_ACCESS.equals(rights) &&
                    (justification == null || justification.isEmpty()) ){

                res.append("\t\t\thttp://hdl.handle.net/");
                res.append(handle);
                res.append(" sem justificação de embargo.");
                res.append(" ");
                res.append(rights);
                res.append("\tRelation:");
                res.append(relation != null ? (relation.length() >0 ? " SIM" : " NO") : " NO");
                res.append("\n");
                /*res.append("\t\t\thttp://dev2.rcaap.pt/entities/publication/");
                res.append(Item_UUID);
                res.append("\n");*/
            }
    }
}
