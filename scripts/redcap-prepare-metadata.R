# a guide script to use rabvRedcapProcessing

# Install package
# if not already installed:
# install.packages("devtools")

devtools::install_github("RAGE-toolkit/rabvRedcapProcessing", force = TRUE)

library(rabvRedcapProcessing)
library(dplyr)
library(here)

## read_data ####

# This should automatically find file if it's in the current project directory
filepath <- here("data", "test_data", "test-metadata.csv")

# Alternatively, Run this command to choose your input file
#filepath <- file.choose()

myData <- read_data(filepath)

## read_and_parse_dict ####

# Uses the built-in dictionary by default
# Alternatively specify a URL to a custom dictionary
myDicts <- read_and_parse_dict()

## compare_cols_to_dict ####

updated_data <- compare_cols_to_dict(dayta = myData)

# Read any messages carefully

## tidy_up_values ####

updated_data <- tidy_up_values(updated_data)

## scan_mismatched_levels ####

# Available coded columns
names(myDicts)

# View dictionary values for selected fields
dict_fields <- c(
  "sample_tissuetype",
  "ngs_prep",
  "hmpcr_n405",
  "test_centre"
)

lapply(
  dict_fields,
  function(x) {
    cat("\n====================\n")
    cat("Dictionary:", x, "\n")
    print(myDicts[[x]])
  }
)

# Check coded columns for values that do not match the dictionary
cols_to_check <- c(
  "sample_tissuetype",
  "sample_buffer",
  "country",
  "hmpcr_n405",
  "test_centre",
  "ngs_platform",
  "nanopore_platform"
)

for (col in cols_to_check) {
  cat("\n====================\n")
  cat("Checking:", col, "\n")
  
  scan_mismatched_levels(
    dayta = updated_data,
    dicts = myDicts,
    col_to_check = col
  )
}

# Note:
# ⚠️ You are responsible for ensuring that all values in coded
# columns match the dictionary values before proceeding.

# Process any mismatched values using custom scripts outside
# the package as necessary.

## create final diagnosis ####

updated_data2 <- create_diagnostic_result_rule(updated_data)

## recode data ####

recoded_data <- recode_data(
  dicts = myDicts,
  dayta = updated_data2
)

## final processing ####

out_data <- final_processing(mydata = recoded_data)

## create output filenames ####

make_output_file <- function(filepath, suffix) {
  file.path(
    dirname(filepath),
    paste0(
      tools::file_path_sans_ext(basename(filepath)),
      suffix
    )
  )
}

diagnostic_outfile <- make_output_file(
  filepath,
  "_diagnostic_form.csv"
)

sequencing_outfile <- make_output_file(
  filepath,
  "_sequencing_form.csv"
)

## write outputs ####

write.csv(
  out_data$diagnostic_form,
  diagnostic_outfile,
  row.names = FALSE
)

write.csv(
  out_data$sequencing_form,
  sequencing_outfile,
  row.names = FALSE
)
