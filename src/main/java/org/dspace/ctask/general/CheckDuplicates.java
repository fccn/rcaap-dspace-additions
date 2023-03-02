package org.dspace.ctask.general;

import org.apache.logging.log4j.Logger;
import org.dspace.content.BitstreamFormat;
import org.dspace.content.DSpaceObject;
import org.dspace.content.EntityType;
import org.dspace.content.Item;
import org.dspace.curate.AbstractCurationTask;
import org.dspace.curate.Curator;
import org.dspace.curate.Distributive;

import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.Set;

@Distributive
public class CheckDuplicates extends AbstractCurationTask {
    private static Logger log = org.apache.logging.log4j.LogManager.getLogger(CheckDuplicates.class);

    String ITEM_TITLE = "dc.title";
    String ITEM_TYPE = "dc.type";
    String ITEM_DATE_ISSUED = "dc.date.issued";

    protected HashMap<Integer, Set<String>> itemTable = new HashMap<Integer, Set<String>>();

    @Override
    public int perform(DSpaceObject dso) throws IOException {
        itemTable.clear();
        distribute(dso);
        formatResults();
        return Curator.CURATE_SUCCESS;
    }

    @Override
    protected void performItem(Item item) throws SQLException, IOException {
        String title = itemService.getMetadata(item, ITEM_TITLE);
        String type = itemService.getMetadata(item, ITEM_TYPE);
        String dateIssued = itemService.getMetadata(item, ITEM_DATE_ISSUED);
        String handle = item.getHandle();

        type = type != null ? type : "";
        dateIssued = dateIssued != null ? dateIssued : "";

        /*EntityType entityType = itemService.getEntityType(Curator.curationContext(), item);
        String label = entityType != null ? entityType.getLabel(): "";*/
        //log.info("title: " + title + " ->label: " + label);
        if(title!= null && item.isArchived() && !item.isWithdrawn()) {
            int hashValue = (title.replaceAll("\\s*", "").toLowerCase().trim() + type.trim() + dateIssued.trim()).hashCode();
            if (itemTable.containsKey(hashValue)) {
                itemTable.get(hashValue).add(handle);
            } else {
                Set<String> handles = new LinkedHashSet<String>();
                handles.add(handle);
                itemTable.put(hashValue, handles);
            }
        }

    }

    private void formatResults() throws IOException {
        StringBuilder sb = new StringBuilder();
        sb.append("\n");
        for (Integer it : itemTable.keySet()) {
            if(itemTable.get(it).size() > 1){
                sb.append("\t")
                    .append("Podem ser duplicados:");
                itemTable.get(it).forEach(handle -> {
                        sb.append(" ")
                                .append("http://hdl.handle.net/")
                                .append(handle).append(", ");
                });
                sb.append("\n");
            }
        }
        itemTable.clear();
        report(sb.toString());
        setResult(sb.toString());
    }
}
