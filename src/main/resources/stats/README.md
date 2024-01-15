# Description

This script inteads to help migrating data from UMinho's stats addon of DS5 version to DSpace Solr Estatistics. This script will only export data from UMinho's stats addon into an intermediate and well known DSpace format (https://wiki.lyrasis.org/display/DSDOC5x/SOLR+Statistics).
Then, using DSpace available tools (https://wiki.lyrasis.org/display/DSDOC5x/SOLR+Statistics+Maintenance), it would be possible to ingest the exported content.


# RCAAP_export_addonstats.sh script

This script exports data from DS5x UMinho stats, namely: views, downloads and workflows as CSV files (at `/tmp` directorty) to be imported as DSpace Solr Statistics.

| Argument | Description |
| --- | --- |
| `--help` | It will list the complete guide for all supported options. |
| `--dbname` | Database name to use to Export data (default: dspace). |
| `--all` | Extract all data (it extract data from the begining ). |
| `--year` | Extract data from a specific year. |
| `--month` | Extract data from a specific month. If `--year` not specified, it will export data from that month of the current year |


The exported content, will be available at `/tmp` dir.

## Executing

if you want to *export all* statistics data:

```bash
bash [PATH]/RCAAP_export_addonstats.sh --all
```

if you just want to export a specific month, from a specific month, as an example may 2014: you can use:
```bash
bash [PATH]/RCAAP_export_addonstats.sh --year 2014 --month 5
```

if you want to export data from all 2018 year, you can use:
```bash
bash [PATH]/RCAAP_export_addonstats.sh --year 2018
```

# Ingesting

To ingest the exported content please check DSpace documentation: https://wiki.lyrasis.org/display/DSDOC5x/SOLR+Statistics+Maintenance

```bash 
[dspace]/bin/dspace solr-import-statistics
```