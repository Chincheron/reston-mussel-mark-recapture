# Data Sources

* ID and describe each source file

# Review raw data files

## Release Data

* Released tag data is in multiple places in and doesn't seem to match
    * 'Summary' sheet from 'first set' workbook says 1224 releases at Glade and 1578 at Snakeden. Most other values reference data, but these totals are hardcoded. Report has actual numbers released per location within each site which match these values (Tables 2 and 3 and text). But can't find these data in sheets. 
    * '2024 Snakeden MR' sheet from 24/25 summary workbook has list of tags with a site added to column. Excluding 'O' tags (which represent new tags during sampling), there are 2,800 tags. This closely matches the total from report (2802). But the totals per site are different 1131 and 1669 for Glade and Snakeden, respectively
    * '2025 Where Found Snakeden' and '2025 Where Found Glad' sheets from 24/25 summary workbook has list of tags with a site added to column. Excluding 'O' tags (which represent new tags during sampling), there are 2,802 tags. This matches the total from report (2802), but the totals per site are different 1132 and 1670 for Glade and Snakeden, respectively
* Most up to date/processed mark-recapture data (i.e., encounter data) appears to be in the below four sheets from '2024 and 2025 Summary - 1.xlsx':
    * Sheets:
        * 2024 Snakeden MR
        * 2024 Glade MR
        * 2025 Snakeden MR
        * 2025 Glade MR
    * Encounter data should pull from this source for further processing

# Data Validation and QA

* Load encounter data from '2024 and 2025 Summary - 1.xlsx' (four sheets referenced above)
* Encounter history QA/QC
* Missing/null values, duplicates, validate data types and formats, flag outliers, assess completeness/consistency (cross check numbers against reports/known values, etc.)

# Data Cleaning

* Handle missing values
* Remove/merge duplicates
* Formatting errors/typos
* Standardize categories and labels
* Handle outliers

# Data Transformation

* Normalize/scale fields as needed
* Encode dummy values/etc.
* Date/time formats and calcualte any associated time values
* Calculate any new fields
* Reshape data as needed for analysis

# Data Merging

* Merge release and encounter data if not done earlier
* Deal with conflicts in naming/etc.
* Confirm correct merging (expected row counts, etc.)

# Exploratory Data Analysis

# Output 

* Export final data for analysis
* Schema description/etc.

# Logging

* save QA steps for review
* Log number of rows/data at each step (e.g. Input - xxx rows, Output - yyy rows)