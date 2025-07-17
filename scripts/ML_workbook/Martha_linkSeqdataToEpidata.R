

source("./Martha_workbook/data_sorting.R")

names(combined_EA)
lab_data_TZ <- combined_EA %>%
  dplyr::filter(country == "Tanzania")

# Contact tracing data ###########

# clean up the column sample id to match metadata sampleID

lab_data_TZ <- lab_data_TZ %>%
  # Drop sample IDs that are NA
  dplyr::filter(!sample_id %in% c("NC", "Lunascript", "NC_KCRI_21_Nov_2022", 
                                  "NC_KCRI_RABV_10_March_2022", "NC_KCRI_Training_21_04_2021", 
                                  "NC_NIMAIST_6th_sept_2019", "NC_KCRI_12_November_2021")) %>%
  # Remove space between "SD" and numbers
  dplyr::mutate(sample_id = str_replace(sample_id, "SD\\s*(\\d+)", "SD\\1"),
                year = as.Date(year, "%Y-%m-%d")) %>%
  # Strip everything after and including the first space
  dplyr::mutate(sample_id = str_replace(sample_id, "\\s.*", ""))


lab_data_TZ$sample_id
lab_data_TZ$year


epi_data_animal <- read.csv("./contact_tracing/animal_ct_2024-07-29.csv") %>%
  dplyr::mutate(date_collection = as.Date(date_collection, "%Y-%m-%d"))

# clean up
epi_data_animal <- epi_data_animal %>%
  drop_na(sample_ID) %>%
  # Convert to uppercase
  dplyr::mutate(sample_ID = str_to_upper(sample_ID)) %>%
  # Filter out irregular IDs
  dplyr::filter(!sample_ID %in% c("KAREN NOTE", "SAMPLE", "UNKNOWN") & !str_detect(sample_ID, "\\?")) %>%
  # Remove space between "SD" and numbers
  dplyr::mutate(sample_ID = str_replace(sample_ID, "SD\\s*(\\d+)", "SD\\1")) %>%
  # Remove space between "RAB" and numbers
  dplyr::mutate(sample_ID = str_replace(sample_ID, "RAB\\s*(\\d+)", "RAB\\1")) %>%
  # Strip everything after space, /, ., or ( and the characters themselves
  dplyr::mutate(sample_ID = str_replace(sample_ID, "[\\s/\\.(].*", ""))



epi_data_animal$sample_ID


# columns to compare

names(lab_data_TZ)

names(epi_data_animal)



# Identify records in both datasets using sample_id / sample_ID
merged_data <- lab_data_TZ %>%
  inner_join(epi_data_animal, by = c("sample_id" = "sample_ID"), relationship = "many-to-many")

# Count the number of records in both files
num_records_in_both <- nrow(merged_data)
print(paste("Number of records in both files:", num_records_in_both))

# Compare columns year == date_collection, region == region, place == district
mismatched_rows <- merged_data %>%
  dplyr::filter(#year != date_collection | 
                  region.x != region.y | place != district)

# Output rows with mismatched values
mismatched <- mismatched_rows %>%
  select(sample_id, year, date_collection, region.x, region.y, place, district)

write.csv(mismatched, "./Martha_workbook/mismatched.csv")

# IBCM data ###########

# List sheets in excel file
excel_sheets("./ibcm/ibcm_update_08Oct24_ML.xlsx")
# Load the data and handle mixed date formats
ibcm_data <- read_excel("./ibcm/ibcm_update_08Oct24_ML.xlsx", sheet = "Collected samples from March 20") %>%
  drop_na(RUA1030, Date) %>%  # Drop rows with missing sample IDs or dates
  dplyr::mutate(
    sample_ID = str_replace_all(RUA1030, "\\s+", ""), # strip white space
    # Convert serial numbers to dates and preserve existing date formats
    Date = dplyr::case_when(
      is.na(as.numeric(Date)) ~ as.Date(Date, "%d/%m/%Y"),  # Handle date strings
      TRUE ~ as.Date(as.numeric(Date), origin = "1899-12-30")  # Convert serial numbers to dates
    )
  ) %>%
  dplyr::select(sample_ID, District, Region, Date, Comments)


names(ibcm_data)

sample_ids_ibcm <- ibcm_data$sample_ID

ids_in_master_data <- sample_ids_ibcm[sample_ids_ibcm %in% lab_data_TZ$sample_id]

### ids missing in CT and IBCM



missed_samples <- lab_data_TZ %>%
  dplyr::filter(
    !sample_id %in% epi_data_animal$sample_ID, 
    !sample_id %in% ibcm_data$sample_ID
  )

View(missed_samples)
# district, date collected, sample id
names(missed_samples)

missed_samples <- missed_samples %>%
  dplyr::select(sample_id, place, region, year)

write.csv(missed_samples, "./Martha_workbook/problems/missing_samples_in_CTandIBCM.csv")


ibcm_ids_missed_by_contact_tracing <- ids_in_master_data[!ids_in_master_data %in% merged_data$sample_id]

print(paste("Number of records in both files:", length(ibcm_ids_missed_by_contact_tracing)))

ibcm_data <- ibcm_data %>%
  dplyr::filter(sample_ID %in% ibcm_ids_missed_by_contact_tracing)


# Identify records in both datasets using sample_id / sample_ID
merged_data2 <- lab_data_TZ %>%
  inner_join(ibcm_data, by = c("sample_id" = "sample_ID"), relationship = "many-to-many")

names(merged_data2)
# Compare columns year == date_collection, region == region, place == district
mismatched_rows2 <- merged_data2 %>%
  dplyr::select(sample_id, region, Region, place, District, year, Date)

mismatched_rows2


###
# IBCM data no sample IDs ###########
ibcm_data2 <- read.csv("./ibcm/processed_VET.csv") %>%
  dplyr::mutate(DATE_SAMPLED = as.Date(DATE_SAMPLED, "%Y-%m-%d"))
names(ibcm_data2)


# How many NA date added ?
sum(is.na(ibcm_data2$DATE_SAMPLED))

# Gurdeep metadata
lab_data_TZ


# Perform inner join using specified columns
combined_data <- lab_data_TZ %>%
  inner_join(ibcm_data2, by = c("year" = "DATE_SAMPLED")) %>%
  drop_na(year)

# Compare the columns and select specific columns of interest
comparison_results <- combined_data %>%
  dplyr::mutate(region_match = ifelse(region == new_region, TRUE, FALSE),
                place_match = ifelse(place == new_district, TRUE, FALSE)) %>%
  dplyr::select(sample_id, year, region, new_region, region_match, place, new_district, place_match) %>%
  # drop ids to be resolved in contact tracing dataset
  dplyr::filter(!sample_id %in% merged_data$sample_id)

# Display
comparison_results

View(comparison_results)


