#----------------------------------------------------------------------------------------------------
# Functions to download WPP2024 data fertility and mortality data, 
# filter for a given country and selected years, and save as .csv files
#----------------------------------------------------------------------------------------------------
# Increase the time limit for downloads
options(timeout=2000)

# Load necessary library
library(data.table)
require(R.utils)

#----------------------------------------------------------------------------------------------------
# Download the data from the WPP 2024 and save as .csv ----

download_WPP2024 <- function() {
  # Create a sub-folder called "Data_all" to save compressed WPP files.
  if (!dir.exists("Data_all")) {
    dir.create("Data_all")
  }

  # URL and local target filenames (.csv.gz).
  files <- data.table(
    url = c(
      "https://population.un.org/wpp/assets/Excel%20Files/1_Indicator%20(Standard)/CSV_FILES/WPP2024_Fertility_by_Age1.csv.gz",
      "https://population.un.org/wpp/assets/Excel%20Files/1_Indicator%20(Standard)/CSV_FILES/WPP2024_Life_Table_Complete_Medium_Female_1950-2023.csv.gz",
      "https://population.un.org/wpp/assets/Excel%20Files/1_Indicator%20(Standard)/CSV_FILES/WPP2024_Life_Table_Complete_Medium_Male_1950-2023.csv.gz",
      "https://population.un.org/wpp/assets/Excel%20Files/1_Indicator%20(Standard)/CSV_FILES/WPP2024_Life_Table_Complete_Medium_Female_2024-2100.csv.gz",
      "https://population.un.org/wpp/assets/Excel%20Files/1_Indicator%20(Standard)/CSV_FILES/WPP2024_Life_Table_Complete_Medium_Male_2024-2100.csv.gz"
    ),
    target = c(
      "Data_all/WPP2024_Fertility_by_Age1.csv.gz",
      "Data_all/WPP2024_Life_Table_Complete_Medium_Female_1950-2023.csv.gz",
      "Data_all/WPP2024_Life_Table_Complete_Medium_Male_1950-2023.csv.gz",
      "Data_all/WPP2024_Life_Table_Complete_Medium_Female_2024-2100.csv.gz",
      "Data_all/WPP2024_Life_Table_Complete_Medium_Male_2024-2100.csv.gz"
    )
  )

  for (i in seq_len(nrow(files))) {
    if (!file.exists(files$target[i])) {
      message("Downloading: ", basename(files$target[i]))
      download.file(files$url[i], destfile = files$target[i], mode = "wb", quiet = FALSE)
    } else {
      warning(basename(files$target[i]), " already exists in Data_all")
    }
  }

  return("World Population Prospects 2024 data downloaded and cached as compressed .csv.gz files.")
}

#----------------------------------------------------------------------------------------------------
# Filter fertility and mortality data from the WPP 2024 for a given country and selected years and save as .csv ----

filter_WPP2024 <- function(Country, Year_Min = 1950, Year_Max = 2100) { 

  # Create a sub-folder called "Data" to save the filtered WPP data if it does not exist.
  if (!dir.exists("Data")) {
    dir.create("Data")
  }

  # Load compressed WPP fertility data and filter for the requested country and years.
  fertility <- fread(
    "Data_all/WPP2024_Fertility_by_Age1.csv.gz",
    select = c("Location", "Time", "Variant", "AgeGrpStart", "ASFR")
  )[
    Location == Country & Time >= Year_Min & Time <= Year_Max & Variant == "Medium",
    .(year = Time, age = AgeGrpStart, ASFR)
  ]

  # Save filtered fertility data as .csv file
  fwrite(fertility, paste0("Data/WPP2024_Fertility_",Country,".csv"), row.names = FALSE)

  # Load compressed WPP life tables and keep only the needed columns.
  mortality_sources <- c(
    "Data_all/WPP2024_Life_Table_Complete_Medium_Female_1950-2023.csv.gz",
    "Data_all/WPP2024_Life_Table_Complete_Medium_Male_1950-2023.csv.gz",
    "Data_all/WPP2024_Life_Table_Complete_Medium_Female_2024-2100.csv.gz",
    "Data_all/WPP2024_Life_Table_Complete_Medium_Male_2024-2100.csv.gz"
  )

  mortality <- rbindlist(lapply(mortality_sources, function(path) {
    fread(path, select = c("Location", "Time", "Sex", "AgeGrpStart", "qx", "mx"))
  }), use.names = TRUE, fill = TRUE)[
    Location == Country & Time >= Year_Min & Time <= Year_Max,
    .(year = Time, Sex, age = AgeGrpStart, qx, mx)
  ]

  # Save filtered mortality data as .csv file
  fwrite(mortality, paste0("Data/WPP2024_Mortality_",Country,".csv"), row.names = FALSE)

}