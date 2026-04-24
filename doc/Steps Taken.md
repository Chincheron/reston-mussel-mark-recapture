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

1) Load encounter data from '2024 and 2025 Summary - 1.xlsx' in long format (sheets/ranges of data to be loaded are found in config.yaml)
2) Deal with Null values
    1) **Removed 13 rows with null values for 'Tag Number'**. These represent blank rows in the imported encounter data
    2) Remaining null values should not be removed (missing lengths, etc.)
3) Deal with duplicate values
    1) Exact duplicates
        1) 19 exact duplicates but all are due to unknown/untagged tag numbers. Will handle at later step
    2) Tag duplicates (based on tag number, occasion, and site)
        1) Most are unknown/untagged  which are dealt with later
        2) 6 actual duplicates:
            1) B013 - potentially a typo for one mussel or double-counted but no way to tell. Longer length (93) is closer to lengths on other occasions
                * **Kept longer length (93)** 
            2) B083 - Lengths are quite different so likely one was recorded incorrectly. Longer length was closer to other occasions
                * **Kept longer length (89.5)** 
            3) B444 - Lengths are quite different. Went with longer length based on temporal trends of other occasions
                * **Kept longer length (96.7)**
            4) C167 - Lengths are quite different. Kept shorter length based on other occasions
                * **Kept shorter length (74.4)**
            5) C891 - Dead with no length. Recorded as two different locations (riffle 3 and pool 3) but unclear where it was actually found
                * **Pick one or mark as unknown?** #TODO
            6) O062 - Similar lengths. Went with smaller based on lengths at other occasions
                * **Kept shorter length (90.8)**
4) Validate data types and formats
    1) `Length (mm)` was character instead of numeric due to various non-numeric values. Most were no data ("-") or data that should have been in other columns ("dead"). Four were numbers that were uncertain. Following decisions were made regarding theese non-numeric values:
        1) Where `Length (mm)` was "-", "DEAD", or "dead": **Changed values to NA**
        2) Where `Length (mm)` was "112.3(???)": **Changed to 112.3**
            * Not found on any other occasions. Unusually large but kept value of 112.3 
        3) Where `Length (mm)` was "66.4 (66.9?)": **Changed to "66.4"**
            * Based on lengths at other occasions
        4) Where `Length (mm)` was "75.1 (76.1?)": **Changed to "76.1"**
            * Based on lengths at other occasions
        5) Where `Length (mm)` was "83(.9?)": **Changed to "83.9"**  
            * Not found on any other occasions but kept as 83.9
5) Validate value ranges and categories
    1) Confirm no extreme or completely implausible values (e.g., negative or large lengths, reasonable date ranges) for these columns:
        * "Length (mm)"
        * "occasion"
        * "date"
    2) Standardize accepted values for each category column:
        1) Location Found
        2) Status
            * **"alive" > "Alive"**
            * **"dead" > "Dead"**
        3) Where Found
        4) site
            * snakeden
            * glade
6) Validate Tag Format (i.e., X000)
    1) **"Unknown" and "Untagged" values (and typos of same) > "Untagged"**
    2) **"Shell Piece", "Shell Half", and variations/typos of same > "Shell Piece"**
    3) **Capitalize all tags where first letter was lower case**  
    4) Four cases where last digit of tag is missing. No feasible way of determining correct tag. Most likely will classify as Untagged when preparing for MARK analysis
        * **No change - Dealt with at later step**
    5) One case where letter is unknown (?800). No feasible way of determining correct tag (Releases included B800, C800, and D800). Most likely will classify as Untagged when preparing for MARK analysis
        * **No change - Dealt with at later step**
6) Assess completeness/consistency
    1) Crosscheck against report totals
        1) Figure 2 (Alive and Dead found on each occasion by site)
            1) glade:
                1) Occasion 5 A/D
                    * 264/33 - report 
                    * 262/32 - data 
                    * Discrepancy due to duplicate removal
                2) Occasion 6 A
                    * 271 - report
                    * 269 - data
                    * Duplicate removal
                3) Occasion 7 A
                    * 214 - report
                    * 213 - data
                    * Duplicate removal
            2) snakeden:
                1) Occasion 4 A/D
                    * 35/41 - report
                    * 33/43 - data
                    * Processed and raw data both show 33/42. Unclear where 35/41 from report is coming from
                2) Occasion 7 D
                    * 40 - report
                    * 39 - data
                    * Processed and raw data both show 39. Unclear where 40 from report is coming from


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
    1) Data validation
        a) Load Data
            * Input - NA
            * Output - 2,684 rows
        b) Validate Data
            * Input - 2,684 rows
            * Remove 13 