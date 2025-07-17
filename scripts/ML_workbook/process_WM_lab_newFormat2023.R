
library(tidyverse)

#Read stuff #####

# Read file
WM_file <- read.csv("./existing_data/WM_lab_newFormat_14072025.csv") %>%
  dplyr::mutate(
    ngs_rundate = dmy(ngs_rundate)
  )

head(WM_file)



# Helper functions

source("./Martha_workbook/process_WM_lab_newFormat2023_Helper.R")
    # reads Dict




data_dict$`Variable...Field.Name`

## Duplicate samples ######
# Check for duplicate sample IDs

print(paste0("There are ", sum(duplicated(WM_file$sample_id)), " duplicates"))


# Check if duplicate sample ids have the same sample_labid

duplicates2 <- WM_file %>%
  # Only sample_ids with more than one row
  group_by(sample_id) %>%
  filter(n() > 1) %>%
  # For each such sample_id, count distinct lab‐IDs & list them
  summarise(
    n_records       = n(),
    seqID_distinct  = n_distinct(sample_sequenceid),
    seqID_values    = paste(unique(sample_sequenceid), collapse = ", ")
  ) %>%
  ungroup()


write.csv(duplicates2, "./Martha_workbook/duplicates_WMlabnewformat2023_seq_ID.csv")

# Assign duplicate_id to duplicates

WM_file <- WM_file %>%
  group_by(sample_id) %>%
  mutate(duplicate_id = row_number()) %>%
  ungroup()


head(WM_file)


## Rename where necessary #######

WM_file <- WM_file %>%
  dplyr::rename(
    # dict = data
    genbank_accession = Genbank_accession,
    lateral_flow_test = lft,
    ngs_prep = ngs_library_type,
    rtassay = rt_rtpcr_assay,
    rtqpcr = rt_rtpcr,
    hmpcr_n405 = hn_rtpcr,
    sample_sequenceid = ngs_sampleid
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
unique(WM_file$primer_scheme) # this too

unique(WM_file_recoded$sample_tissuetype)

WM_file_recoded <- WM_file %>%
  
# 1. Tissue type
  dplyr::mutate(
    sample_tissuetype = str_trim(sample_tissuetype),
    sample_tissuetype = case_when(
      # everything “gland” and its variants → Salivary gland
      sample_tissuetype %in% c("Salivary gland", "Saliva gland")    ~ "Salivary gland",
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
    # trim stray spaces
    sbuf = str_trim(sample_buffer),
    # assign code based on pattern
    sample_buffer_code = case_when(
      str_detect(sbuf, regex("glycerol[- ]?saline", ignore_case = TRUE))  ~ buffer_dict["Glycerol-saline"],
      str_detect(sbuf, regex("RNA[- ]?shield",    ignore_case = TRUE))    ~ buffer_dict["RNAshield"],
      str_detect(sbuf, regex("RNA[- ]?later",     ignore_case = TRUE))   ~ buffer_dict["RNAlater"],
      str_detect(sbuf, regex("^(None)$",          ignore_case = TRUE))    ~ buffer_dict["None"],
      str_detect(sbuf, regex("^Fresh|^No buffer", ignore_case = TRUE))   ~ buffer_dict["None"],
      # everything else (including "" or NA) → Unknown
      TRUE                              ~ buffer_dict["Unknown"]
    )
  ) %>%
  dplyr::select(-sbuf) %>%
  
# 3. Country 
  dplyr::mutate(
    # recode blanks into "Tanzania"
    country = if_else(country == "", "Tanzania", country)
  )

  


# Codes for REDCAP usings mini dicts -- fingers crossed this goes smooth #########





# Filter out columns not in dict ? -- Check if this is absolutely necessary 




# Add dag column








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

# To do -- apply dicts dynamically
final_data <- bind_rows(diagnostic_data, sequencing_data) %>%
  dplyr::mutate(
    # Apply country dictionary
    country = recode(country, !!!country_dict),
    hmpcr_n405 = recode(as.character(hmpcr_n405), !!!hmpcr_dict),
    # Apply lateral flow dictionary (assuming it's named correctly)
    lateral_flow_test = recode(as.character(lateral_flow_test), !!!lateral_flow_dict),
    # Standardize and apply test center dictionary
    test_centre = recode(test_centre, !!!test_center_dict)
  )




cols_to_upload <- names(combined_EA)[names(combined_EA) %in% d_dict$`Variable...Field.Name`]
cols_to_upload



dplyr::mutate(
  redcap_data_access_group = "east_africa"
)
