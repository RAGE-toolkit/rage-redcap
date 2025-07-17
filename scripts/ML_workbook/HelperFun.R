

# Specify the columns that belong to each instrument (adjust based on actual columns)
diagnostic_columns <- c("sample_id", "redcap_repeat_instrument", "redcap_repeat_instance", "sample_labid", 
                        "sample_sequenceid", "sample_batchid", "apha_sub", "apha_rv", "sample_tissuetype", 
                        "sample_buffer", "country", "hmpcr_n405", "rtassay", "rtqpcr", "lateral_flow_test", 
                        "diagnostic_result", "test_centre", "diag_notes")

sequencing_columns <- c("sample_id", "redcap_repeat_instrument", "redcap_repeat_instance", "ngs_runid",
                        "duplicate_id", "ngs_rundate", "ngs_location", "ngs_provider", "ngs_submission", "ngs_platform", 
                        "nanopore_platform", "ngs_flowcell", "illumina_platform", "ngs_prep", "ngs_barcode", "ngs_library", 
                        "total_reads", "mapped_reads", "mean_depth", "stdev_depth", "median_depth", "minimum_reads", "maximum_reads", 
                        "genomecov_depthx1", "genomecov_depthx5", "genomecov_depthx20", "genomecov_depthx100", "genbank_accession", 
                        "consensus_coverage", "ngs_notes")





# Define country dictionary
country_dict <- c(
  "Tanzania" = "0",
  "Kenya" = "1",
  "Uganda" = "2",
  "Philippines" = "3",
  "Peru" = "4",
  "Nigeria" = "5",
  "Malawi" = "6"
)


# Define sample tissue dictionary
tissue_dict <- c(
  "Brain" = "1",
  "Salivary gland" = "2",   # dataset reads `Saliva gland`
  "Saliva" = "3",
  "Other" = "4"
)

# Define the sample buffer dictionary
buffer_dict <- c(
  "Glycerol-saline" = "0",
  "RNAshield" = "1",      # data reads `RNA Shield`
  "RNAlater" = "2",
  "None" = "3",
  "Unknown" = "4"
)

# Define the hmpcr dictionary    
hmpcr_dict <- c(        # data all blanks
  "Pos1" = "0",
  "Pos2" = "1",
  "Neg" = "2"
)


# Define the rt_assay dictionary
rt_assay_dict <- c(        # data all blanks
  "Sybr" = "0",
  "Ln34" = "1",
  "Unknown" = "2"
)

# Define the lateral flow dictionary
lateral_flow_dict <- c(        # column missing in data
  "Positive" = "0",
  "Negative" = "1"
)

# Define the test center dictionary
test_center_dict <- c(
  "APHA" = "0",
  "TVLA" = "1",
  "CVL" = "2",
  "SUA" = "3",
  "UNITID" = "4",
  "Other" = "5"
)


# Define the ngs platform dictionary
ngs_platform_dict <- c(
  "Nanopore" = "0",
  "Illumina" = "1",
  "454 pyrosequencing" = "2",
  "Sanger" = "3",
  "PacBio" = "4"
)


# Define the nanopore platform dictionary
nanopore_platform_dict <- c(
  "Minion" = "0",
  "Gridion" = "1",
  "Unknown" = "2"
)


# Define the illumina platform dictionary
illumina_platform_dict <- c(
  "Miseq" = "0",
  "Nextseq" = "1",
  "GAIIx" = "2",
  "Unknown" = "3"
)

# Define the ngs prep dictionary
ngs_prep_dict <- c(
  "Metagenomic" = "0",
  "Amplicon" = "1",
  "Direct RNA" = "2"
)

# Define the ngs library dictionary
ngs_library_dict <- c(
  "Pass" = "0",
  "Fail" = "1"
)
























