library(dplyr)
library(lubridate)
library(stringr)

## link genetic and epi data

source("scripts/redcap-getMetadata.R")
dim(df_per_80)

# import epi data
epi <- read.csv("peru/raw_data/epi_metadata/Rabies focus control data_SEQ-unclean_v2.csv")

# match gen to epi
df_per_80$sample_id %in% epi$ID
df_per_80$sample_id[!df_per_80$sample_id %in% epi$ID]

# subset epi 
epi_subset <- epi[epi$ID %in% df_per_80$sample_id,]
epi_subset <- epi_subset |> 
  dplyr::mutate(Taxon = ID, .before = 1)
#write.table(epi_subset, "peru/epi_subset99.txt", sep="\t",quote=F,row.names=F)

# sort dates
names(epi_subset)



# keep all cols with dates
dates <- epi_subset %>%
  select(ID,matches("day|month|year", ignore.case = TRUE))

# Get all column names

# Define all date groups manually
date_groups <- list(
  symptoms_appeared = c("day_sympoms_appeared", "month_sympoms_appeared", "year_sympoms_appeared"),
  killed           = c("day_killed", "month_killed", "year_killed"),
  Sampling         = c("Sampling_day", "Sampling_month", "Sampling_year"),
  containment       = c("day_containent_started", "month_containent_started", "year_containent_started"),
  Confirmation     = c("Confirmation_day", "Confirmation_month", "Confirmation_year"),
  brain_shipping   = c("brain_sampling_shipping_day", "brain_sampling_shipping_month", "brain_sampling_shipping_year")
)

#  Create full date columns
for(group_name in names(date_groups)) {
  cols <- date_groups[[group_name]]
  if(all(cols %in% names(epi_subset))) {
    # Create Date object
    epi_subset[[paste0("date_", group_name)]] <- make_date(
      year  = epi_subset[[cols[3]]],
      month = epi_subset[[cols[2]]],
      day   = epi_subset[[cols[1]]]
    )
    # Optional: human-readable format
    epi_subset[[paste0("date_", group_name, "_formatted")]] <- format(epi_subset[[paste0("date_", group_name)]], "%d-%b-%Y")
  }
}

#  Create best_date column (priority order)
epi_subset <- epi_subset %>%
  mutate(
    best_date = coalesce(
      date_symptoms_appeared_formatted,
      date_killed_formatted,
      date_Sampling_formatted,
      date_containment_formatted,
      date_Confirmation_formatted,
      date_brain_shipping_formatted
      
    )
  )
write.csv(epi_subset, "peru/epi_subset99_improvedDates.csv",row.names=F)
# create data for clockor2/phylogenetic reconstructions
temporal <- epi_subset %>%
  select(tip=Taxon, date=best_date, group=District)
# Function to convert Date to decimal year
decimal_date <- function(date) {
  year(date) + (yday(date) - 1) / ifelse(leap_year(year(date)), 366, 365)
}
temporal$date <- dmy(temporal$date)
temporal$date <- decimal_date(temporal$date)
temporal$group <- str_to_title(temporal$group)
#write.csv(temporal, "peru/epi_subset99_clockor2.csv",row.names=F)
#write.table(temporal, "peru/epi_subset99_beast.txt",row.names=F, sep="\t")
