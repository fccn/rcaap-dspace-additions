-- . DROP de Views do esquema STATS
-- . Eliminar o esquema STATS

BEGIN;

DROP VIEW IF EXISTS stats.z_view_unagg_metadata_coll_month_2;
DROP VIEW IF EXISTS stats.z_view_unagg_metadata_coll_month_1;
DROP VIEW IF EXISTS stats.z_view_unagg_item_coll_month;
DROP VIEW IF EXISTS stats.z_view_unagg_country_coll_month;
DROP VIEW IF EXISTS stats.z_view_unagg_coll_month;
DROP VIEW IF EXISTS stats.z_download_unagg_metadata_coll_month_2;
DROP VIEW IF EXISTS stats.z_download_unagg_metadata_coll_month_1;
DROP VIEW IF EXISTS stats.z_download_unagg_item_coll_month;
DROP VIEW IF EXISTS stats.z_download_unagg_country_coll_month;
DROP VIEW IF EXISTS stats.z_download_unagg_coll_month;
DROP VIEW IF EXISTS stats.v_ycct;
DROP VIEW IF EXISTS stats.v_view_coll;
DROP VIEW IF EXISTS stats.v_item_type_coll;
DROP VIEW IF EXISTS stats.v_item_language_coll;
DROP VIEW IF EXISTS stats.v_item_commit_coll;
DROP VIEW IF EXISTS stats.v_item_coll;
DROP VIEW IF EXISTS stats.v_item_access_coll;
DROP VIEW IF EXISTS stats.v_files_coll;
DROP VIEW IF EXISTS stats.v_download_coll;
DROP VIEW IF EXISTS stats.z_view_unagg_metadata_comm_month_2;
DROP VIEW IF EXISTS stats.z_view_unagg_metadata_comm_month_1;
DROP VIEW IF EXISTS stats.z_view_unagg_item_comm_month;
DROP VIEW IF EXISTS stats.z_view_unagg_country_comm_month;
DROP VIEW IF EXISTS stats.z_view_unagg_comm_month;
DROP VIEW IF EXISTS stats.z_download_unagg_metadata_comm_month_2;
DROP VIEW IF EXISTS stats.z_download_unagg_metadata_comm_month_1;
DROP VIEW IF EXISTS stats.z_download_unagg_item_comm_month;
DROP VIEW IF EXISTS stats.z_download_unagg_country_comm_month;
DROP VIEW IF EXISTS stats.z_download_unagg_comm_month;
DROP VIEW IF EXISTS stats.v_view_comm;
DROP VIEW IF EXISTS stats.v_item_type_comm;
DROP VIEW IF EXISTS stats.v_item_language_comm;
DROP VIEW IF EXISTS stats.v_item_commit_comm;
DROP VIEW IF EXISTS stats.v_item_comm;
DROP VIEW IF EXISTS stats.v_item_access_comm;
DROP VIEW IF EXISTS stats.v_files_comm;
DROP VIEW IF EXISTS stats.v_download_comm;
DROP VIEW IF EXISTS stats.v_communities2item;
DROP VIEW IF EXISTS stats.v_workflow;
DROP VIEW IF EXISTS stats.v_workflow_comm;
DROP VIEW IF EXISTS stats.v_item2bitstream;
DROP VIEW IF EXISTS stats.v_files;
DROP VIEW IF EXISTS stats.v_itemsbydateavailable;
DROP VIEW IF EXISTS stats.v_itemsbydate;
DROP VIEW IF EXISTS stats.v_view_author;
DROP VIEW IF EXISTS stats.v_download_author;
DROP VIEW IF EXISTS stats.v_itemsbyauthor;
DROP VIEW IF EXISTS stats.v_item;
DROP VIEW IF EXISTS stats.v_bundle;
DROP VIEW IF EXISTS stats.z_view_unagg_metadata_month_2;
DROP VIEW IF EXISTS stats.z_view_unagg_metadata_month_1;
DROP VIEW IF EXISTS stats.z_download_unagg_metadata_month_2;
DROP VIEW IF EXISTS stats.z_download_unagg_metadata_month_1;
DROP VIEW IF EXISTS stats.v_eperson;
DROP VIEW IF EXISTS stats.v_community;
DROP VIEW IF EXISTS stats.v_collection;
DROP VIEW IF EXISTS stats.v_item_type;
DROP VIEW IF EXISTS stats.v_item_language;
DROP VIEW IF EXISTS stats.v_item_commit;
DROP VIEW IF EXISTS stats.v_item_access;
DROP VIEW IF EXISTS stats.dcvalue;

-- Apagar STATS
DROP SCHEMA IF EXISTS stats CASCADE;

COMMIT;