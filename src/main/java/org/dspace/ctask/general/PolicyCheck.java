package org.dspace.ctask.general;

import org.dspace.authorize.ResourcePolicy;
import org.dspace.content.Bitstream;
import org.dspace.content.Bundle;
import org.dspace.content.Item;
import org.dspace.curate.Curator;
import org.dspace.curate.Distributive;
import org.dspace.eperson.Group;

import java.io.IOException;
import java.sql.SQLException;
import java.util.Iterator;
import java.util.List;

@Distributive
public class PolicyCheck extends Distribute{

    private static String RIGHTS = "dc.rights";
    private String OPEN_ACCESS = "openaccess";


    @Override
    protected void performItem(Item item) throws SQLException, IOException {
        String rights = itemService.getMetadata(item, RIGHTS);

        if (item.isArchived() && !item.isWithdrawn() && rights != null
                && !OPEN_ACCESS.equals(rights.replaceAll("\\s*","").toLowerCase()))  {

            String handle = item.getHandle();
            boolean isAnonymous = false;
            int i = 0;
            List<Bundle> bundles =  itemService.getBundles(item,"ORIGINAL");

            //VER OS BUNDLES DO PROFILEFORMATS
            for (Bundle bundle : bundles) {
                if(isAnonymous)
                    break;
                List<ResourcePolicy> resourcePolicy = bundle.getResourcePolicies();
                for(ResourcePolicy rp : resourcePolicy){
                    if(isAnonymous)
                        break;
                    if(rp.getGroup() != null)
                        isAnonymous = rp.getGroup().getName().equals(Group.ANONYMOUS) ? true : isAnonymous;
                }

                //Check if the bitstreams have also anonymous access
                /***
                 * TODO: (Fev 2023) ONLY ONE OR ALL? - See after testing - This case verifie only one in an Anonymous state
                 */
                if(isAnonymous){
                    boolean hasBitStreamAnonymous = false;
                    for(Bitstream bs : bundle.getBitstreams()){
                        if(hasBitStreamAnonymous)
                            break;
                        List<ResourcePolicy> bitstreamResourcePolicies = bs.getResourcePolicies();
                        for (ResourcePolicy bsrp : bitstreamResourcePolicies){
                            if(hasBitStreamAnonymous)
                                break;
                            if(bsrp.getGroup() != null)
                                hasBitStreamAnonymous = bsrp.getGroup().getName().equals(Group.ANONYMOUS) ? true: hasBitStreamAnonymous;
                        }
                    }
                    if(hasBitStreamAnonymous){
                        res.append("\t\t\thttp://hdl.handle.net/");
                        res.append(handle);
                        res.append(" dc.rights não está de acordo com as politicas de acesso \n");
                    }
                }

            }

        }
    }

}
