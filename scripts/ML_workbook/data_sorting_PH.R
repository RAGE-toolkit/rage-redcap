# Philippines data ####
## Essel to send an updated dataset -- done

# List sheets in excel file
excel_sheets("./Martha_workbook/ph_redcap_2024.v1.xlsx")

# Read distinct sheets
labrecords <- read_excel("./Martha_workbook/ph_redcap_2024.v1.xlsx", sheet = "lab_record")
metadata <- read_excel("./Martha_workbook/ph_redcap_2024.v1.xlsx", sheet = "ph_metadata_210")

# Data dictionary
d_dict <- read.csv("./existing_data/RABVlab_DataDictionary_2023-04-19.csv")

#check duplicates
duplicates2 <- labrecords %>%
  dplyr::filter(
    duplicated(sample_ID) | duplicated(sample_ID, fromLast = TRUE)
  )

# none in metadata
metadata %>%
  dplyr::filter(
    duplicated(`Isolate ID`) | duplicated(`Isolate ID`, fromLast = TRUE)
  )

# handle duplicates using run date
# Convert NGS_runDate to Date format
labrecords$run_date <- as.Date(labrecords$run_date, format="%d-%b-%Y")

# Create the duplicate_id column
labrecords <- labrecords %>%
  group_by(sample_ID) %>%
  arrange(sample_ID, run_date) %>%
  mutate(duplicate_id = row_number())

# Ensure the duplicate_id is 1 for non-duplicated sample_ID
labrecords <- labrecords %>%
  ungroup() %>%
  dplyr::mutate(duplicate_id = ifelse(duplicated(sample_ID) | duplicated(sample_ID, fromLast = TRUE), duplicate_id, 1))


# merge

# match sample names as advised by Essel
# Apply the recoding
labrecords <- labrecords %>%
  dplyr::mutate(
    sample_ID = case_when(
      sample_ID == "98-134" ~ "Z-98-134",
      sample_ID == "98-206" ~ "Z-98-206",
      sample_ID == "98-285" ~ "Z-98-285",
      sample_ID == "98-286" ~ "Z-98-286",
      sample_ID == "98-335" ~ "Z-98-335",
      sample_ID == "R5-09" ~ "R5-22-09",
      sample_ID == "H-23-011Sk_12" ~ "H-23-011Sk12",
      TRUE ~ sample_ID
    ),
    country = "Philippines" # add country
  )


# check if everything in metadata present in labrecords
metadata$`Isolate ID`[!metadata$`Isolate ID` %in% labrecords$sample_ID] 
labrecords$sample_ID[!labrecords$sample_ID %in% metadata$`Isolate ID`] 
    # all good

# combine    
combined_ph <- labrecords %>%
  left_join(., metadata, by=c("sample_ID"="Isolate ID"))

# match col names to data dict
names(combined_ph)
d_dict$Variable...Field.Name


combined_ph <- combined_ph %>%
  dplyr::rename_all(~str_to_lower(str_trim(.)))  %>%  # strip extra white spaces
  dplyr::rename(
    ngs_runid = run_name, 
    ngs_flowcell = flowcell_id,
    ngs_rundate = run_date,
    minimum_reads = min_reads,
    maximum_reads = max_reads,
    genomecov_depthx1 = basescovered_1,
    genomecov_depthx5 = basescovered_5,
    genomecov_depthx20 = basescovered_20,
    genomecov_depthx100 = basescovered_100,
    consensus_coverage = nonmaskedconsensuscov,
    ngs_barcode = barcode,
    mean_depth = meanreads,
    stdev_depth = sd_reads,
    median_depth = median_reads
    
  )



# columns in data not in dict
names(combined_ph)[!names(combined_ph) %in% d_dict$`Variable...Field.Name`]
# columns missing in data
d_dict$`Variable...Field.Name`[!d_dict$`Variable...Field.Name` %in% names(combined_ph)]


# Add columns in dict but missing in data
  # Identify missing columns
missing_cols <- d_dict$`Variable...Field.Name`[!d_dict$`Variable...Field.Name` %in% names(combined_ph)]

# Add missing columns as empty string
for (col in missing_cols) {
  combined_ph[[col]] <- ""
}

# Optionally, match column order to dictionary 
combined_ph <- combined_ph[, d_dict$`Variable...Field.Name`, drop = FALSE]


# redcap streamlining
source("./Martha_workbook/HelperFun.R")


# Create diagnostic data rows
diagnostic_data_PH <-combined_ph %>%
  dplyr::mutate(
    redcap_repeat_instrument = "diagnostic",
    redcap_repeat_instance = duplicate_id,
    sample_buffer = "Unknown",
    rtqpcr = "Unknown",
    test_centre = "Other"
  ) %>%
  dplyr::select(all_of(diagnostic_columns)) 



# Create sequencing data rows
sequencing_data_PH <- combined_ph %>%
  dplyr::mutate(
    redcap_repeat_instrument = "sequencing",
    redcap_repeat_instance = duplicate_id,
    ngs_platform = "Nanopore",
    nanopore_platform = "Minion"
  ) %>%
  dplyr::select(all_of(sequencing_columns))




# Combine both datasets into one, filling missing values with NA
final_data_PH <- bind_rows(diagnostic_data_PH, sequencing_data_PH) %>%
  dplyr::mutate(
    # Apply country dictionary
    country = recode(country, !!!country_dict),
    
    # Apply sample tissue dictionary, correcting any alternative text first
    sample_tissuetype = recode(as.character(sample_tissuetype), !!!tissue_dict),
    
    
    # apply sample buffer dictionary
    sample_buffer = recode(as.character(sample_buffer), !!!buffer_dict),
    
    # Convert hmpcr_n405 to character type and apply hmpcr dictionary
    hmpcr_n405 = recode(as.character(hmpcr_n405), !!!hmpcr_dict),
    
    # Convert rtqpcr to character type and apply rt_assay dictionary
    rtqpcr = recode(as.character(rtqpcr), !!!rt_assay_dict),
    
    # Apply lateral flow dictionary (assuming it's named correctly)
    lateral_flow_test = recode(as.character(lateral_flow_test), !!!lateral_flow_dict),
    
    # Standardize and apply test center dictionary
    test_centre = recode(as.character(test_centre), !!!test_center_dict),
    
    # apply ngs platform dictionary
    ngs_platform = recode(as.character(ngs_platform), !!!ngs_platform_dict),
    
    # Apply nanopore platform dictionary
    nanopore_platform = recode(as.character(nanopore_platform), !!!nanopore_platform_dict),
    
    # Apply illumina platform dictionary
    illumina_platform = recode(as.character(illumina_platform), !!!illumina_platform_dict),
    
    # Convert ngs_prep to character type and apply ngs_prep dictionary
    ngs_prep = recode(as.character(ngs_prep), !!!ngs_prep_dict),
    
    # Apply ngs library dictionary
    ngs_library = recode(as.character(ngs_library), !!!ngs_library_dict)
  )

# export
cols_to_upload_PH <- names(final_data_PH)[names(final_data_PH) %in% d_dict$`Variable...Field.Name`]


PH_df_redcap <- final_data_PH %>%
  dplyr::select(all_of(c("redcap_repeat_instrument", "redcap_repeat_instance", cols_to_upload_PH))) %>%
  dplyr::select(sample_id, everything()) %>%
  dplyr::mutate(across(everything(), as.character)) %>%  # Convert all columns to character
  mutate_all(~ replace_na(., ""))  # Replace all NA values with an empty string


write_csv(PH_df_redcap, "./Martha_workbook/final_data/PH_final_data.csv")


# non-data-dict columns
non_dict_cols <- names(combined_ph)[!names(combined_ph) %in% d_dict$`Variable...Field.Name`]
cols_to_select <- c("sample_id", non_dict_cols)

PH_non_dict <- combined_ph %>%
  dplyr::select(all_of(cols_to_select))

write_csv(PH_non_dict, "./Martha_workbook/final_data/PH_data_not_in_dict.csv")
