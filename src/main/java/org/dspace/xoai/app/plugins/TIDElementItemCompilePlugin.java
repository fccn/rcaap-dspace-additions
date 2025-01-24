/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * http://www.dspace.org/license/
 */
package org.dspace.xoai.app.plugins;

import java.util.List;

import com.lyncode.xoai.dataprovider.xml.xoai.Element;
import com.lyncode.xoai.dataprovider.xml.xoai.Element.Field;
import com.lyncode.xoai.dataprovider.xml.xoai.Metadata;
import org.dspace.content.Item;
import org.dspace.core.Context;
import org.dspace.xoai.app.XOAIExtensionItemCompilePlugin;
import org.dspace.xoai.util.ItemUtils;

/**
 * TIDElementItemCompilePlugin aims to add structured information about the
 * TID identifier. It will be used to expose it as an AlternateIdentifier

 * The xoai document will be enriched with a structure like that
 * <pre>
 * {@code
 *    <element name="identifier">
 *     <element name="uri">
 *       <element name="none">
 *         <field name="value">http://hdl.handle.net/101766/831</field>
 *         <field name="tid">urn:tid:101766831</field>
 *       </element>
 *     </element>
 * }
 * </pre>
 * Returning Values are based on:
 * @see org.dspace.access.status.DefaultAccessStatusHelper  DefaultAccessStatusHelper
 */
public class TIDElementItemCompilePlugin implements XOAIExtensionItemCompilePlugin {

    @Override
    public Metadata additionalMetadata(Context context, Metadata metadata, Item item) {
        Element dc;
        List<Element> elements = metadata.getElement();
        if (ItemUtils.getElement(elements, "dc") != null) {
            dc = ItemUtils.getElement(elements, "dc");
        } else {
            return metadata;
        }

        Element identifier;
        if (ItemUtils.getElement(dc.getElement(), "identifier") != null) {
            identifier = ItemUtils.getElement(dc.getElement(), "identifier");
        } else {
            return metadata;
        }

        // get a dc.identifier.tid
        if (ItemUtils.getElement(identifier.getElement(), "tid") != null) {
            Element tid = ItemUtils.getElement(identifier.getElement(), "tid");

            if (tid != null) {
                Field tidField = getFirstElementField(tid.getElement(), "value");
                if (tidField == null) {
                    return metadata;
                }

                String urnTIDFieldValue = "urn:tid:" + tidField.getValue();

                if (tidField != null) {
                    Element uri;
                    if (ItemUtils.getElement(identifier.getElement(), "uri") != null) {
                        uri = ItemUtils.getElement(identifier.getElement(), "uri");
                    } else {
                        uri = ItemUtils.create("uri");
                        identifier.getElement().add(uri);
                    }

                    Element none;
                    if (ItemUtils.getElement(uri.getElement(), "none") != null) {
                        none = ItemUtils.getElement(uri.getElement(), "none");
                    } else {
                        none = ItemUtils.create("none");
                        uri.getElement().add(none);
                    }

                    none.getField().add(ItemUtils.createValue("value", urnTIDFieldValue ));
                }
            }
        }

        return metadata;
    }
    
    private static Element.Field getFirstElementField(List<Element> list, String name) {
        for (Element e : list) {
            return getElementField(e.getField(),name);
        }

        return null;
    }
    
    private static Element.Field getElementField(List<Element.Field> list, String name) {
        for (Element.Field e : list) {
            if (name.equals(e.getName())) {
                return e;
            }
        }

        return null;
    }

}