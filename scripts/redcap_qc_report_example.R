library(redcapAPI)
library(dplyr)
library(ggplot2)

############################################################
# 1. Connect to REDCap
############################################################

# If rcon does not already exist
source("scripts/redcap-api.R")

############################################################
# 2. Download all records
############################################################

df <- exportRecordsTyped(rcon)

cat("Downloaded", nrow(df), "rows from REDCap\n")

############################################################
# 3. Separate diagnostic and sequencing forms
############################################################

df_diag <- df %>%
  filter(is.na(redcap_repeat_instrument) |
           redcap_repeat_instrument == "")

df_seq <- df %>%
  filter(redcap_repeat_instrument == "Sequencing")

############################################################
# 4. Get field lists from metadata
############################################################

meta <- rcon$metadata()

diagnostic_fields <- meta %>%
  filter(form_name == "diagnostic") %>%
  pull(field_name)

sequencing_fields <- meta %>%
  filter(form_name == "sequencing") %>%
  pull(field_name)

############################################################
# 5. Keep only relevant columns
############################################################

df_diag_clean <- df_diag %>%
  select(sample_id, any_of(diagnostic_fields))

df_seq_clean <- df_seq %>%
  select(
    sample_id,
    redcap_repeat_instance,
    any_of(sequencing_fields)
  )

############################################################
# 6. Merge sequencing and diagnostic data
############################################################

df_merged <- df_seq_clean %>%
  left_join(df_diag_clean, by = "sample_id")

cat("Merged dataset contains",
    nrow(df_merged),
    "sequencing records\n")

############################################################
# 7. Remove negative controls
############################################################

df_clean <- df_merged %>%
  filter(negative_control_sample != "Yes")

############################################################
# 8. Keep latest sequencing attempt
############################################################

df_latest <- df_clean %>%
  group_by(sample_id) %>%
  filter(
    redcap_repeat_instance ==
      max(redcap_repeat_instance, na.rm = TRUE)
  ) %>%
  ungroup()

cat("Latest-instance dataset contains",
    nrow(df_latest),
    "samples\n")

############################################################
# 9. Calculate coverage percentage
############################################################

df_latest <- df_latest %>%
  mutate(
    consensus_coverage = as.numeric(consensus_coverage),
    genome_length = case_when(
      grepl("Philippines", country, ignore.case = TRUE) ~ 11932,
      grepl("Peru", country, ignore.case = TRUE) ~ 11923,
      grepl("Tanzania", country, ignore.case = TRUE) ~ 11923,
      grepl("Kenya", country, ignore.case = TRUE) ~ 11923,
      TRUE ~ NA_real_
    ),
    coverage_percent =
      (consensus_coverage / genome_length) * 100
  )

## Question: can you figure out what's wrong with Tanzania/Kenya data?
############################################################
# 10. Assign QC category
############################################################

df_latest <- df_latest %>%
  mutate(
    qc_status = case_when(
      coverage_percent >= 90 ~ "High quality",
      coverage_percent >= 80 ~ "Usable",
      TRUE ~ "Low coverage"
    )
  )

############################################################
# 11. Produce QC summary
############################################################

qc_summary <- df_latest %>%
  group_by(country, qc_status) %>%
  summarise(
    n_samples = n(),
    .groups = "drop"
  )

print(qc_summary)

############################################################
# 12. Export clean dataset
############################################################

write.csv(
  df_latest,
  "outputs/examples/clean_redcap_sequencing_data.csv",
  row.names = FALSE
)

write.csv(
  qc_summary,
  "outputs/examples/sequencing_qc_summary.csv",
  row.names = FALSE
)

cat("Files written successfully\n")

############################################################
# 13. Plots to look at country coverage profiles
############################################################

# Calculate coverage %
df_cov <- df_latest %>%
  filter(!is.na(consensus_coverage)) %>%
  mutate(
    consensus_coverage = as.numeric(consensus_coverage),
    genome_length = case_when(
      grepl("Philippines", country, ignore.case = TRUE) ~ 11932,
      grepl("Peru", country, ignore.case = TRUE) ~ 11923,
      grepl("Tanzania", country, ignore.case = TRUE) ~ 11923,
      grepl("Kenya", country, ignore.case = TRUE) ~ 11923,
      TRUE ~ NA_real_
    ),
    coverage_percent = (consensus_coverage / genome_length) * 100
  ) %>%
  filter(!is.na(coverage_percent))

# Histogram by country
ggplot(df_cov, aes(x = coverage_percent)) +
  geom_histogram(binwidth = 5) +
  geom_vline(xintercept = 80, linetype = "dashed") +
  geom_vline(xintercept = 90, linetype = "dashed") +
  facet_wrap(~country, scales = "free_y") +
  labs(
    x = "Genome coverage (%)",
    y = "Number of samples",
    title = "Coverage distribution by country"
  ) +
  theme_bw()
