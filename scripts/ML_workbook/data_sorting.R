

# Kenya and Tanzani data (Gurdeep)

# Libraries ####
require(pacman)
pacman::p_load(
  readxl,
  tidyverse
)



# Data dictionary ####

d_dict <- read.csv("./existing_data/RABVlab_DataDictionary_2023-04-19.csv")

d_dict$`Variable...Field.Name`

######################################################################################
# East Africa data --updated ####
## Read#####
# List sheets in excel file
excel_sheets("./Martha_workbook/G_runs_metadata_updated.xlsx")

# Read distinct sheets
Rabv_labrecords_final <- read_excel("./Martha_workbook/G_runs_metadata_updated.xlsx", sheet = "Rabv_labrecords_final")
Metadata <- read_excel("./Martha_workbook/G_runs_metadata_updated.xlsx", sheet = "Metadata")
Removed_fasta <- read_excel("./Martha_workbook/G_runs_metadata_updated.xlsx", sheet = "Removed_fasta")

# Convert the year column from Excel date serial number to a year
Metadata <- Metadata %>%
  dplyr::mutate(year = as.numeric(year),  # Ensure 'year' is numeric
         year = format(as.Date(year, origin = "1899-12-30"), "%Y-%m-%d"))

## Clean up #####
# strip everything after and including the first whitespace 
Removed_fasta$SampleID <- sub("\\s.*", "", Removed_fasta$SampleID)

# Create a named vector for SampleID and Sample_sequenceID
recode_values <- c(
  "NCAA/RB004" = "RB004",
  "SD789 (sequenced twice)" = "SD789",
  "Z00861857 (missing in mapping stat)" = "Z00861857",
  "SD753 (Sequenced twice)" = "SD753",
  "Human saliva (HS001)" = "HS001",
  "Human brain (HS002)" = "HS002",
  "Human lymph node (HS003)" = "HS003",
  "Malinyi (MR008)" = "MR008",
  "Mtwara R (MT006)" = "MT006",
  "Mbingu- dog (RB002)" = "RB002",
  "Mbingu-Bovine (RB003)" = "RB003",
  "Arusha (RB004)" = "RB004",
  "SD750 (Failed in medaka)" = "SD750"
)

# first leave important notes so we can move this to Notes column
recode_values2 <- recode_values[-c(2:7, 13)]

# Apply the recoding
Rabv_labrecords_final <- Rabv_labrecords_final %>%
  dplyr::mutate(
    Sample_sequenceID = case_when(
      SampleID %in% names(recode_values2) ~ SampleID,
      TRUE ~ as.character(Sample_sequenceID)
    ),
    SampleID = recode(SampleID, !!!recode_values),
    Notes = case_when(
      SampleID == "RB004" ~ "NCAA/RB004",
      SampleID == "SD789" ~ "sequenced twice",
      SampleID == "Z00861857" ~ "missing in mapping stat",
      SampleID == "HS001" ~ "Human saliva",
      SampleID == "HS002" ~ "Human brain",
      SampleID == "HS003" ~ "Human lymph node",
      SampleID == "MR008" ~ "Malinyi",
      SampleID == "MT006" ~ "Mtwara R",
      SampleID == "RB002" ~ "Mbingu-dog",
      SampleID == "RB003" ~ "Mbingu-Bovine",
      SampleID == "RB004" ~ "Arusha",
      SampleID == "SD750" ~ "Failed in medaka",
      TRUE ~ Notes
    )
  )


names(Rabv_labrecords_final)

## Negative control IDs ####
# Recode SampleID where it is 'NC'
Rabv_labrecords_final$SampleID <- ifelse(
  Rabv_labrecords_final$SampleID == "NC", 
  paste("NC", Rabv_labrecords_final$NGS_runID, sep = "_"),
  Rabv_labrecords_final$SampleID
)
Removed_fasta$SampleID <- ifelse(
  Removed_fasta$SampleID == "NC", 
  paste("NC", Removed_fasta$NGS_runID, sep = "_"),
  Removed_fasta$SampleID
)

## Compare labrecords and removed ####
# Compare Removed fasta and Labrecords to see if all records in Removed fasta are in Labrecords
Removed_fasta$SampleID[!Removed_fasta$SampleID%in% Rabv_labrecords_final$SampleID]
                        # all samples now in Rabv_labrecords_final

## Duplicates #####
# Check for duplicate sample IDs in Rabv_labrecords_final
duplicates <- Rabv_labrecords_final %>%
  dplyr::filter(
    duplicated(SampleID) | duplicated(SampleID, fromLast = TRUE)
    )
    # How to handle?
# Convert NGS_runDate to Date format
Rabv_labrecords_final$NGS_runDate <- as.Date(Rabv_labrecords_final$NGS_runDate, format="%d-%b-%Y")

# Check for any remaining NA values in the converted dates
if(any(is.na(Rabv_labrecords_final$NGS_runDate))) {
  print("Some dates could not be converted. Please check the format.")
  print(Rabv_labrecords_final[is.na(Rabv_labrecords_final$NGS_runDate), ])
}
# Create the duplicate_id column
Rabv_labrecords_final <- Rabv_labrecords_final %>%
  group_by(SampleID) %>%
  arrange(SampleID, NGS_runDate) %>%
  mutate(duplicate_id = row_number())

# Ensure the duplicate_id is 1 for non-duplicated SampleID
Rabv_labrecords_final <- Rabv_labrecords_final %>%
  ungroup() %>%
  dplyr::mutate(duplicate_id = ifelse(duplicated(SampleID) | duplicated(SampleID, fromLast = TRUE), duplicate_id, 1))


## Merge lab records with Metadata ##### 
  # Check if samples in Removed_fasta present in Rabv_labrecords_final
Metadata$ID[!Metadata$ID%in% Rabv_labrecords_final$SampleID]
Rabv_labrecords_final$SampleID[!Rabv_labrecords_final$SampleID%in% Metadata$ID]
                  # all looks good
# merge
combined_EA <- Rabv_labrecords_final %>%
  left_join(., Metadata, by=c("SampleID"="ID"))

names(combined_EA)
  
## Match to d-dict ####

mismatches <- combined_EA[combined_EA$`Genbank number.x` != combined_EA$`Genbank number.y`,][,c("SampleID", "Genbank number.x", "Genbank number.y")] %>%
  drop_na()

# clean up to match
combined_EA <- combined_EA %>%
  # match names to data dict
  dplyr::rename_all(~str_to_lower(str_trim(.)))  %>%  # strip extra white spaces
  dplyr::rename(
    sample_id = sampleid,
    genbank_accession = `genbank number.y`, # Genbank.y is the correct one - confirmed by Kirstyn
    rtqpcr = `rt-qpcr`,
    ngs_notes = notes,
    minimum_reads = min_reads,
    maximum_reads = max_reads,
    mean_depth = meanreads,
    median_depth = median_reads,
    test_centre = test_center,
    ngs_barcode = barcode,
    diag_notes = other_positive_diagnostic,
    ngs_prep = library_type,
    ngs_flowcell = flowcell_id,
    consensus_coverage = nonmaskedconsensuscov
  ) 

# Fill in missing country info (to help split the data into KE and Tz later)
combined_EA <- combined_EA %>%
  dplyr::mutate(
    # Fixing NMIST typo
    test_centre = ifelse(test_centre == "NIMST", "NMAIST", test_centre),  
    
    # Update diag_notes for test_centre not in the specified dictionary
    diag_notes = ifelse(
      !test_centre %in% c("0", "APHA", "1", "TVLA", "2", "CVL", "3", "SUA", "4", "UNITID"),
      # Append test_centre to diag_notes if diag_notes is not empty
      if_else(!is.na(diag_notes) & diag_notes != "",
              paste(diag_notes, test_centre, sep = "; "),  # Append with a separator
              test_centre),  # Otherwise, just assign test_centre
      diag_notes
    ),
    # Update country based on the test_centre
    country = case_when(
      !is.na(country) ~ country,  # Keep existing country values unchanged
      test_centre %in% c("KCRI", "NMAIST") ~ "Tanzania",  # If test_centre is KCRI or NMAIST, assign Tanzania
      test_centre == "UNITID" ~ "Kenya",  # Assign Kenya for '4, UNITID'
      TRUE ~ NA_character_  # Otherwise, assign NA
    ),
    
    # Standardizing test_centre names
    test_centre = case_when(
      test_centre %in% c("0", "APHA", "1", "TVLA", "2", "CVL", "3", "SUA", "4" , "UNITID") ~ test_centre,  # Keep valid test centres
      TRUE ~ "Other"  # For all other cases, set as 'Other'
    ),
    # Create the ngs_library column based on genbank_accession values
    ngs_library = if_else(!is.na(genbank_accession) & genbank_accession != "", "Pass", ""),
    # add missing cols
    ngs_location = "",
    rtassay ="",
    nanopore_platform ="",
    illumina_platform ="",
    # update details for Neg controls
    lateral_flow_test = ifelse(grepl("^NC_", sample_id)| sample_id == "Lunascript", "Negative", lateral_flow_test),
    sample_buffer = ifelse(grepl("^NC_", sample_id)| sample_id == "Lunascript", "None", sample_buffer),
    sample_tissuetype = ifelse(grepl("^NC_", sample_id)| sample_id == "Lunascript", "Other", sample_tissuetype),
    
    sample_buffer = ifelse(sample_id %in% c("HB002", "HS001", "HS002", "HS003"), "None", sample_buffer),
    sample_tissuetype = ifelse(sample_id == "HS003", "Other", sample_tissuetype)
    
  )




names(combined_EA)
d_dict$`Variable...Field.Name`

unique(combined_EA$test_centre)

# columns in data not in dict
names(combined_EA)[!names(combined_EA) %in% d_dict$`Variable...Field.Name`]
# matches
cols_to_upload <- names(combined_EA)[names(combined_EA) %in% d_dict$`Variable...Field.Name`]
cols_to_upload
# columns missing in data
d_dict$`Variable...Field.Name`[!d_dict$`Variable...Field.Name` %in% names(combined_EA)]



# Compare this to Kirstyn's data #####
## read 
K_data <- read.csv("./existing_data/WM_lab_newFormat_2023.csv")

## compare
### samples in Gurdeeps data not in K_data
combined_EA$sample_id[!combined_EA$sample_id %in% K_data$sample_id]

K_data$sample_id[!K_data$sample_id %in% combined_EA$sample_id]


## Write to file
cols_in_dict <- d_dict$`Variable...Field.Name`
# add duplicate ID
cols_in_dict<-c(cols_in_dict, "duplicate_id")



# redcap troubleshooting ##########

source("./Martha_workbook/HelperFun.R")


# Create diagnostic data rows
diagnostic_data <-combined_EA %>%
  dplyr::mutate(
    redcap_repeat_instrument = "diagnostic",
    redcap_repeat_instance = duplicate_id
  ) %>%
  dplyr::select(all_of(diagnostic_columns)) 



# Create sequencing data rows
sequencing_data <- combined_EA %>%
  dplyr::mutate(
    redcap_repeat_instrument = "sequencing",
    redcap_repeat_instance = duplicate_id
  ) %>%
  dplyr::select(all_of(sequencing_columns))



# Combine both datasets into one, filling missing values with NA
final_data <- bind_rows(diagnostic_data, sequencing_data) %>%
  dplyr::mutate(
    # Apply country dictionary
    country = recode(country, !!!country_dict),
    
    # Apply sample tissue dictionary, correcting any alternative text first
    sample_tissuetype = recode(
      replace(sample_tissuetype, sample_tissuetype == "Saliva gland", "Salivary gland"),
      !!!tissue_dict
    ),
    
    # Standardize and apply sample buffer dictionary
    sample_buffer = case_when(
      grepl("No buffer", sample_buffer, ignore.case = TRUE) ~ "None",
      grepl("RNA Shield", sample_buffer, ignore.case = TRUE) ~ "RNAshield",
      TRUE ~ sample_buffer
    ),
    sample_buffer = recode(sample_buffer, !!!buffer_dict),
    
    # Convert hmpcr_n405 to character type and apply hmpcr dictionary
    hmpcr_n405 = recode(as.character(hmpcr_n405), !!!hmpcr_dict),
    
    # Convert rtqpcr to character type and apply rt_assay dictionary
    rtqpcr = recode(as.character(rtqpcr), !!!rt_assay_dict),
    
    # Apply lateral flow dictionary (assuming it's named correctly)
    lateral_flow_test = recode(as.character(lateral_flow_test), !!!lateral_flow_dict),
    
    # Standardize and apply test center dictionary
    test_centre = recode(test_centre, !!!test_center_dict),
    
    # Map shorthand and apply ngs platform dictionary
    ngs_platform = case_when(
      ngs_platform == "WG" ~ "Nanopore",  # Replace with correct mapping if needed
      TRUE ~ ngs_platform
    ),
    ngs_platform = recode(ngs_platform, !!!ngs_platform_dict),
    
    # Apply nanopore platform dictionary
    nanopore_platform = recode(nanopore_platform, !!!nanopore_platform_dict),
    
    # Apply illumina platform dictionary
    illumina_platform = recode(illumina_platform, !!!illumina_platform_dict),
    
    # Convert ngs_prep to character type and apply ngs_prep dictionary
    ngs_prep = recode(as.character(ngs_prep), !!!ngs_prep_dict),
    
    # Apply ngs library dictionary
    ngs_library = recode(ngs_library, !!!ngs_library_dict)
  )





KE_TZ_final_data <- final_data %>%
  dplyr::select(all_of(c("redcap_repeat_instrument", "redcap_repeat_instance", cols_to_upload))) %>%
  dplyr::select(sample_id, everything()) %>%
  dplyr::mutate(across(everything(), as.character)) %>%  # Convert all columns to character
  mutate_all(~ replace_na(., ""))  # Replace all NA values with an empty string

write_csv(KE_TZ_final_data, "./Martha_workbook/final_data/KE_TZ_final_data.csv")



############################


# Split by country
KE_combined_df <- final_data %>%
  dplyr::filter(country =="Kenya")
TZ_combined_df <- final_data %>%
  dplyr::filter(country =="Tanzania")

KE_final_df <- KE_combined_df %>%
  dplyr::select(any_of(c("redcap_repeat_instrument", "redcap_repeat_instance", cols_in_dict)))
TZ_final_df <- TZ_combined_df %>%
  dplyr::select(any_of(c("redcap_repeat_instrument", "redcap_repeat_instance", cols_in_dict)))


write_csv(KE_final_df, "./Martha_workbook/final_data/KE_final_data.csv")
write_csv(TZ_final_df, "./Martha_workbook/final_data/TZ_final_data.csv")


# non-data-dict columns

non_dict_columns <- names(combined_EA)[!names(combined_EA) %in% d_dict$`Variable...Field.Name`]
columns_to_select <- c("sample_id", non_dict_columns)

KE_non_dict <- KE_combined_df %>%
  dplyr::select(all_of(columns_to_select))
TZ_non_dict <- TZ_combined_df %>%
  dplyr::select(all_of(columns_to_select))


# resolve mismatches (identified by Martha_linkSeqdataToEpidata.R)
resolved_df <- read.csv("./Martha_workbook/problems/rabies_mismatches_resolved.csv") %>%
  dplyr::mutate(
    year = as.Date(year, format = "%d/%m/%Y"),
    Sikana_confirmed = as.Date(`Sikana.confirmed.dates_Sample.Collected`, format = "%d/%m/%Y")) %>%
  dplyr::select(sample_id, year, Sikana_confirmed)


TZ_non_dict <- TZ_non_dict %>% 
  left_join(., resolved_df, by = c("sample_id", "year"))

# write out epi data
write_csv(KE_non_dict, "./Martha_workbook/final_data/KE_data_not_in_dict.csv")
write_csv(TZ_non_dict, "./Martha_workbook/final_data/TZ_data_not_in_dict.csv")

####contact tracing
contact_animal <- read.csv("./contact_tracing/animal_ct_2024-07-29.csv")
names(contact_animal)
contact_animal$sample_ID %in% TZ_final_df$sample_id
  
contact_animal[contact_animal$sample_ID %in% TZ_final_df$sample_id, ]


######################################################################################
# Philippines data ####
## Essel to send an updated dataset -- done

# List sheets in excel file
excel_sheets("./Martha_workbook/ph_redcap_2024.v1.xlsx")

# Read distinct sheets
labrecords <- read_excel("./Martha_workbook/ph_redcap_2024.v1.xlsx", sheet = "lab_record")
metadata <- read_excel("./Martha_workbook/ph_redcap_2024.v1.xlsx", sheet = "ph_metadata_210")

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
    country = "Phillipines" # add country
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
    mean_depth = meanreads
    
  )



# columns in data not in dict
names(combined_ph)[!names(combined_ph) %in% d_dict$`Variable...Field.Name`]
# columns missing in data
d_dict$`Variable...Field.Name`[!d_dict$`Variable...Field.Name` %in% names(combined_ph)]



# export
PH_final_df <- combined_ph %>%
  dplyr::select(any_of(cols_in_dict))

write_csv(PH_final_df, "./Martha_workbook/final_data/PH_final_data_draft1.csv")


# non-data-dict columns
non_dict_cols <- names(combined_ph)[!names(combined_ph) %in% d_dict$`Variable...Field.Name`]
cols_to_select <- c("sample_id", non_dict_cols)

PH_non_dict <- combined_ph %>%
  dplyr::select(all_of(cols_to_select))

write_csv(PH_non_dict, "./Martha_workbook/final_data/PH_data_not_in_dict.csv")




