package org.dspace.ctask.general;

import org.apache.logging.log4j.Logger;
import org.dspace.content.*;
import org.dspace.core.Constants;
import org.dspace.curate.AbstractCurationTask;
import org.dspace.curate.Curator;

import java.io.IOException;
import java.sql.SQLException;
import java.util.Iterator;
import java.util.List;

abstract class Distribute extends AbstractCurationTask {

    private static Logger log = org.apache.logging.log4j.LogManager.getLogger(Distribute.class);
    StringBuilder res = new StringBuilder();

    /**
     * Perform the curation task upon passed DSO
     *
     * @param dso the DSpace object
     * @throws IOException if IO error
     */
    @Override
    public int perform(DSpaceObject dso) throws IOException {
        res.setLength(0);
        distribute(dso);
        formatResults();
        return Curator.CURATE_SUCCESS;
    }

    /**
     * Distributes a task through a DSpace container - a convenience method
     * @param dso current DSpaceObject
     * @throws IOException if IO error
     */
    @Override
    protected void distribute(DSpaceObject dso) throws IOException {
        try {
            //perform task on this current object
            performObject(dso);

            //next, we'll try to distribute to all child objects, based on container type
            int type = dso.getType();
            if (Constants.COLLECTION == type) {
                Iterator<Item> iter = itemService.findByCollection(Curator.curationContext(), (Collection) dso);
                while (iter.hasNext()) {
                    Item item = iter.next();
                    performObject(item);
                    Curator.curationContext().uncacheEntity(item);
                }
            } else if (Constants.COMMUNITY == type) {
                Community comm = (Community) dso;
                String nameCom = comm.getName();
                res.append("\n\tComunidade: " + nameCom+"\n");
                for (Community subcomm : comm.getSubcommunities()) {
                    distribute(subcomm);
                }
                for (Collection coll : comm.getCollections()) {
                    String nameCol = coll.getName();
                    res.append("\t\tColeção:" + nameCol+"\n");
                    distribute(coll);
                }
            } else if (Constants.SITE == type) {
                List<Community> topComm = communityService.findAllTop(Curator.curationContext());
                res.append("\n");
                for (Community comm : topComm) {
                    distribute(comm);
                }
            }
        } catch (SQLException sqlE) {
            throw new IOException(sqlE.getMessage(), sqlE);
        }
    }

    protected abstract void performItem(Item item) throws SQLException, IOException;

    private void formatResults() throws IOException {
        report(res.toString());
        setResult(res.toString());
    }

}
