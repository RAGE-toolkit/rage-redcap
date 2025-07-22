
library(tidyverse)

#Read stuff #####

# Read file
WM_file <- read.csv("./raw_data/WM_lab_newFormat_14072025.csv") %>%
  dplyr::mutate(
    ngs_rundate = dmy(ngs_rundate)
  )

head(WM_file)

names(WM_file)

# Helper functions

source("./scripts/ML_workbook/process_WM_lab_newFormat2023_Helper.R")
    # reads Dict


data_dict$`Variable...Field.Name`

## Duplicate samples ######
# Check for duplicate sample IDs

print(paste0("There are ", sum(duplicated(WM_file$sample_id)), " duplicates"))


# Check if duplicate sample ids have the same sample_labid

# duplicates2 <- WM_file %>%
#   # Only sample_ids with more than one row
#   group_by(sample_id) %>%
#   filter(n() > 1) %>%
#   # For each such sample_id, count distinct lab‐IDs & list them
#   summarise(
#     n_records       = n(),
#     seqID_distinct  = n_distinct(sample_sequenceid),
#     seqID_values    = paste(unique(sample_sequenceid), collapse = ", ")
#   ) %>%
#   ungroup()


#write.csv(duplicates2, "./Martha_workbook/duplicates_WMlabnewformat2023_seq_ID.csv")



head(WM_file)


## Rename where necessary #######

WM_file <- WM_file %>%
        # Assign duplicate_id to duplicates
  group_by(sample_id) %>%
  mutate(duplicate_id = row_number()) %>%
  ungroup() %>%
         # match dict col names
  dplyr::rename(
    # dict = data
    genbank_accession = Genbank_accession,
    lateral_flow_test = lft,
    ngs_prep = ngs_library_type,
    rtassay = rt_rtpcr_assay,
    rtqpcr = rt_rtpcr,
    hmpcr_n405 = hn_rtpcr,
    sample_sequenceid = ngs_sampleid
  ) %>%
         # make recoding easier
  dplyr::mutate(
    ngs_provider = "",
    ngs_library = "",
    # append the value of test_centre to the existing ngs_notes column instead of overwriting it
    ngs_notes = paste(coalesce(ngs_notes, ""), test_centre, sep = " | "),
    ngs_platform = capitalize_first_word(str_trim(ngs_platform)),
    illumina_platform = capitalize_first_word(str_trim(illumina_platform)),
    nanopore_platform = capitalize_first_word(str_trim(nanopore_platform)),
    ngs_prep = capitalize_first_word(str_trim(ngs_prep))
  )


## Dict vs data  ######
  ### What's missing in the data from the dict/ and the reverse

#  two vectors
file_cols <- names(WM_file)
dict_cols <- data_dict$`Variable...Field.Name`

# what's in WM_file but not in the dictionary?
missing_in_dict <- setdiff(file_cols, dict_cols)
missing_in_dict

# what's in the dictionary but not in WM_file?
missing_in_file <- setdiff(dict_cols, file_cols)
missing_in_file

## Recode mismatched values before coding for redcap #######

unique(WM_file$test_centre) ## to come back # move to `diag_notes`

miniDicts <- read_and_parse_dict("./data_dictionaries/RABVlab_DataDictionary_2025-07-22.csv")
names(miniDicts)

scan_mismatched_levels(dayta = WM_file, dicts = miniDicts, col_to_check = "sample_tissuetype")
scan_mismatched_levels(dayta = WM_file, dicts = miniDicts, col_to_check = "sample_buffer")
scan_mismatched_levels(dayta = WM_file, dicts = miniDicts, col_to_check = "country")
scan_mismatched_levels(dayta = WM_file, dicts = miniDicts, col_to_check = "hmpcr_n405")
scan_mismatched_levels(dayta = WM_file, dicts = miniDicts, col_to_check = "rtassay")
scan_mismatched_levels(dayta = WM_file, dicts = miniDicts, col_to_check = "fat")
scan_mismatched_levels(dayta = WM_file, dicts = miniDicts, col_to_check = "drit")
scan_mismatched_levels(dayta = WM_file, dicts = miniDicts, col_to_check = "test_centre")
scan_mismatched_levels(dayta = WM_file, dicts = miniDicts, col_to_check = "ngs_platform")
scan_mismatched_levels(dayta = WM_file, dicts = miniDicts, col_to_check = "nanopore_platform")
scan_mismatched_levels(dayta = WM_file, dicts = miniDicts, col_to_check = "illumina_platform")
scan_mismatched_levels(dayta = WM_file, dicts = miniDicts, col_to_check = "ngs_prep")
scan_mismatched_levels(dayta = WM_file, dicts = miniDicts, col_to_check = "ngs_library")
scan_mismatched_levels(dayta = WM_file, dicts = miniDicts, col_to_check = "ngs_analysis_type")



unique(WM_file_recoded$sample_tissuetype)

WM_file_ed <- WM_file %>%
  
# 1. Tissue type
dplyr::mutate(
    sample_tissuetype = str_trim(sample_tissuetype),
    sample_tissuetype = case_when(
      # everything “gland” and its variants → Salivary gland
      sample_tissuetype %in% c("Salivary gland", "Saliva gland")    ~ "Salivary_gland",
      # swabs → Saliva
      sample_tissuetype == "Saliva swab"                           ~ "Saliva",
      # keep true Saliva
      sample_tissuetype == "Saliva"                                ~ "Saliva",
      # central‐nervous tissues → Brain
      sample_tissuetype %in% c("Brain", "Spinal cord", "Brain_FTA") ~ "Brain",
      # everything else (including blanks, NFW, lymph node, etc.) → Other
      TRUE                                                         ~ "Other"
    )
  )  %>%
  
# 2. Sample buffer
  dplyr::mutate(
    sample_buffer = str_trim(sample_buffer),
    sample_buffer = case_when(
      sample_buffer == "PBSwash" | is.na(sample_buffer)  ~ "None",
      TRUE                                              ~ sample_buffer
    )
  ) %>%
  
# 3. Country 
  dplyr::mutate(
    # recode blanks into "Tanzania"
    country = if_else(country == "", "Tanzania", country)
  ) %>%
  
# 4. NGS Platform
  dplyr::mutate(
    ngs_platform = str_trim(as.character(ngs_platform)),
    ngs_platform = case_when(
      ngs_platform %in% c("Illumina merge", "Illumina/nanopore merge", "GAIIx") ~ "Illumina",
      ngs_platform == "454" ~ "454 pyrosequencing",
      ngs_platform == "" | is.na(ngs_platform) | ngs_platform == "NA" ~ "Nanopore",
      TRUE ~ ngs_platform )
  )  %>%
  
# 5. nanopore_platform
  dplyr::mutate(
    nanopore_platform = str_trim(nanopore_platform),
    nanopore_platform = case_when(
      nanopore_platform == "" | is.na(nanopore_platform)     ~ "Unknown",
      TRUE                                         ~ nanopore_platform
    )
  )   %>%
  
  # 6. illumina_platform
  dplyr::mutate(
    illumina_platform = str_trim(illumina_platform),
    illumina_platform = case_when(
      illumina_platform == "Gaiix"                      ~ "GAIIx",
      illumina_platform == "" | is.na(illumina_platform)     ~ "Unknown",
      TRUE                                         ~ illumina_platform
    )
  )   %>%
  
  # 7. ngs_analysis_type
  dplyr::mutate(
    ngs_analysis_type = str_trim(ngs_analysis_type),
    ngs_analysis_type = case_when(
      ngs_analysis_type == "single_run" | is.na(ngs_analysis_type)     ~ "Single run",
      ngs_analysis_type == "merged"                                  ~ "Merged runs",
      is.na(ngs_analysis_type) | ngs_analysis_type == "" ~ "Single run",
      TRUE                                         ~ ngs_analysis_type
    )
  )  %>%
  
  # 8. ngs_prep
  dplyr::mutate(
    ngs_prep = str_trim(ngs_prep),
    ngs_prep = case_when(
      ngs_prep == "Sangerpcr"                      ~ "sangerPCR",
      is.na(ngs_prep) | ngs_prep == ""             ~ "Amplicon",
      TRUE                                         ~ ngs_prep
    )
  ) %>%
  
  # Redcap doesnt like the signs & or + in sample_id
  dplyr::mutate(
    sample_id = str_replace_all(sample_id, "[&+]", "_")
  )


  


# Codes for REDCAP usings mini dicts -- fingers crossed this goes smooth #########

WM_file_recoded <- recode_data(dicts = miniDicts, dayta = WM_file_ed) 


sequencingForm <- WM_file_recoded %>%
  dplyr::mutate(
    redcap_data_access_group = "east_africa",
    redcap_repeat_instance = duplicate_id,
    redcap_repeat_instrument = "sequencing",
    ngs_library = "Pass"
  ) %>%
  dplyr::select(all_of(sequencing_columns)) %>%
  dplyr::select(sample_id, everything())  # Moves sample_id to the first column
  


diagnosticForm <- WM_file_recoded %>%
  dplyr::mutate(
    redcap_data_access_group = "east_africa"#,
    # redcap_repeat_instance = duplicate_id,
    # redcap_repeat_instrument = "diagnostic"
  ) %>%
  dplyr::select(all_of(diagnostic_columns)) 

# %>%
#   dplyr::filter(
#     redcap_repeat_instance == 1
#   )  %>%
#   dplyr::select(-redcap_repeat_instance)


duplicated(diagnosticForm$sample_id)





# Combine both datasets into one, filling missing values with NA

final_data <- bind_rows(diagnosticForm, sequencingForm)  %>%
  mutate(across(everything(), as.character)) %>%
  mutate(across(everything(), ~ replace_na(.x, ""))) 
  


write.csv(final_data, "./processed_data/redcap_upload/WM_processed.csv", row.names = F)
write.csv(sequencingForm, "./processed_data/redcap_upload/WM_processed_sequencing.csv", row.names = F)


cols_to_upload <- names(combined_EA)[names(combined_EA) %in% d_dict$`Variable...Field.Name`]
cols_to_upload

unique(final_data$ngs_prep)

unique(final_data$ngs_analysis_type)
