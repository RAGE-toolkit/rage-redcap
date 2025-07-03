### ============================================================================
### Script to compare sequences in FASTA to metadata
### Author: Kirstyn Brunker
### Date: 1 Jul 2025
### Description: This script reads a multi-FASTA file and metadata file,
###              and performs checks for matching sample names, missing entries,
###              or other inconsistencies between the two datasets.
###              It also outputs a filtered FASTA with only matched sequences.
### ============================================================================

# ========================
# 1. Load Required Packages
# ========================
library(tidyverse)
library(Biostrings)  
library(stringr)     

# ========================
# 2. Define File Paths
# ========================
## inputs
fasta_file <- "~/Downloads/East_africa_consensus/all.fasta"
metadata_file <- "~/Downloads/East_africa_consensus/KE_TZ_final_data.csv"

## outputs
# store date to use in output filenames
today <- format(Sys.Date(), "%Y%m%d")
matched_fasta_output <- paste0("processed_data/R-outputs/", today, "_matched_sequences.fasta")

# ========================
# 3. Read in the Data
# ========================
# Read FASTA file
sequences <- readDNAStringSet(fasta_file)
fasta_ids <- names(sequences)

# Read metadata
metadata <- read_csv(metadata_file)

# ========================
# 4. Preprocess & Standardise IDs
# ========================
# If needed, clean FASTA or metadata IDs to ensure they match
# Example: remove suffixes or normalise underscores/dashes
fasta_ids_clean <- str_replace(fasta_ids, "\\.fasta$", "")
metadata_ids <- metadata$sample_id  # Update to match your column name

# ========================
# 5. Perform Checks
# ========================
# Check which FASTA sequences are missing from metadata
missing_in_metadata <- setdiff(fasta_ids_clean, metadata_ids)
# Check which metadata entries are missing in FASTA
missing_in_fasta <- setdiff(metadata_ids, fasta_ids_clean)

# ========================
# 6. Output Summary
# ========================
cat("Number of sequences in FASTA:", length(fasta_ids_clean), "\n")
cat("Number of samples in metadata:", length(metadata_ids), "\n")
cat("Sequences missing from metadata:", length(missing_in_metadata), "\n")
cat("Metadata entries missing from FASTA:", length(missing_in_fasta), "\n")

# Optional: write mismatches to file
writeLines(missing_in_metadata, paste0("processed_data/R-outputs/", today, "_missing_in_metadata.txt"))
writeLines(missing_in_fasta, paste0("processed_data/R-outputs/", today, "_missing_in_fasta.txt"))

# ========================
# 7. Save Cleaned Metadata (if needed)
# ========================
# Example: subset metadata to only matched samples
matched_ids <- intersect(fasta_ids_clean, metadata_ids)
matched_metadata <- metadata %>% filter(sample_id %in% matched_ids)
# write_csv(matched_metadata, paste0("processed_data/R-outputs/", today, "_matched_metadata.csv"))

# ========================
# 8. Output Matched FASTA File
# ========================
# Get original FASTA names that match the cleaned matched IDs
matched_seq_names <- names(sequences)[fasta_ids_clean %in% matched_ids]
matched_sequences <- sequences[matched_seq_names]
writeXStringSet(matched_sequences, matched_fasta_output)
cat("Matched FASTA written to:", matched_fasta_output, "\n")

# ========================
# End of Script
# ========================