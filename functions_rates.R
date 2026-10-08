#----------------------------------------------------------------------------------------------------
# Functions to write SOCSIM fertility and mortality input rate files using WPP2024 data 
# filtered for a given country and selected years
#----------------------------------------------------------------------------------------------------
# Create a sub-folder called "rates" to save the rate files if it does not exist.
ifelse(!dir.exists("rates"), dir.create("rates"), FALSE)
# If the sub-folder name changes, 
# it must be also changed in the functions when opening the output file connection
#----------------------------------------------------------------------------------------------------
#### Write SOCSIM input fertility rates from WPP 2024 data ----

write_socsim_fertility_rates_WPP <- function(Country) {
  
  # Load the WPP data in csv format filtered for the country and years of interest
   ASFR <- read_csv(paste0("Data/WPP2024_Fertility_",Country,".csv"), show_col_types = FALSE)

    # Wrangle data and compute monthly fertility rates
    ASFR <- ASFR %>%
      mutate(ASFR = ASFR/1000,
             age_up = age + 1, # SOCSIM uses the upper age bound
             Month = 0,
             ASFR_mo = ASFR/12) %>%
    select(-ASFR)
  
  # Tibble with expected ages, including lower and upper limits
  Tibble_ages <- tibble(age = c(0, seq(15,50)))
  
  # Add rows with rates = 0 for ages [0-14] and [50-101]
  ASFR <- ASFR %>%
    # create every year × age combination
    complete(year, age = Tibble_ages$age) %>%
    # Fill blanks and compute age_up and Month consistently
    mutate(ASFR_mo = coalesce(ASFR_mo, 0),
           age_up  = case_when(age == 0 ~ 15L,
                               age == 50 ~ 101L,
                               TRUE ~ age + 1L),
           Month   = 0) %>%
    arrange(year, age_up) %>%
    select(year, age_up, Month, ASFR_mo)
  
  # Extract the years in the dataset
  years <- ASFR %>% pull(year) %>% unique()
  
  # Row numbers corresponding to sequence of years of age in ASFR
  rows_ageF <- ASFR %>% pull(age_up) %>% unique() %>% seq_along()
  
  ## Write the fertility rate files for each year
  
  for(year in years) {
    
    # Find the index of each year of the iteration
    n <- which(year == years)
    n_row <- (n-1)*37 + rows_ageF
    
    # Open an output file connection
    outfilename <- file(paste0("rates/",Country,"fert",year), "w")
    # without ".txt" specification as the original files had no format.
    
    # Include Country and year of the corresponding rates
    cat(c("** Period (Monthly) Age-Specific Fertility Rates for", Country, "in", year, "\n"),
        file = outfilename)
    cat(c("* Retrieved from the World Population Prospects 2024", "\n"),
        file = outfilename)
    cat(c("* https://population.un.org/wpp/assets/Excel%20Files/1_Indicator%20(Standard)/CSV_FILES/WPP2024_Fertility_by_Age1.csv.gz", "\n"),
        file = outfilename)
    cat(c("* United Nations. Population Division. Department of Economic and Social Affairs", "\n"),
        file = outfilename)
    cat(c("* Data downloaded on ", format(Sys.time(), format= "%d %b %Y %X %Z"), "\n"),
        file = outfilename)
    cat(c("** NB: The original WPP annual rates have been converted into monthly rates", "\n"),
        file = outfilename)
    cat("\n", file = outfilename)
    
    # Print birth rates (single females)
    cat("birth", "1", "F", "single", "0", "\n", file = outfilename)
    for(i in n_row) {
      cat(c(as.matrix(ASFR)[i,-1], "\n"), file = outfilename) }
    cat("\n", file = outfilename)
    
    # Print birth rates (married females)
    cat("birth", "1", "F", "married", "0", "\n", file = outfilename)
    for(i in n_row) {
      cat(c(as.matrix(ASFR)[i,-1],"\n"), file = outfilename) }
    
    close(outfilename)
    
  }
  
}

#----------------------------------------------------------------------------------------------------
#### Write SOCSIM input mortality rates from WPP 2024 data ----

write_socsim_mortality_rates_WPP <- function(Country) {
  
  # Load the WPP data in csv format filtered for the country and years of interest
  ASMP <- read_csv(paste0("Data/WPP2024_Mortality_",Country,".csv"), show_col_types = FALSE)
  
  # Wrangle data and compute monthly mortality probabilities
  ASMP <- ASMP %>% 
    
    mutate(qx_mo = ifelse(age == 100, 1, 1-(1-qx)^(1/12)), # q100 limited to 1
           age_up = age + 1, # SOCSIM uses the upper age bound
           Month = 0) %>%
    select(c(year, age_up, Month, Sex, qx_mo)) %>%
    pivot_wider(names_from = Sex, values_from = qx_mo)
  
  # Extract the years available in WPP
  years <- ASMP %>% pull(year) %>% unique()
  
  # Row numbers corresponding to sequence of years of age in ASMP
  rows_ageM <- ASMP %>% pull(age_up) %>% unique() %>% seq_along()
  
  ## Write the mortality rate files for each year
  
  for(year in years) {
    
    # Find the index of each year of the iteration
    n <- which(year == years)
    n_row <- (n-1)*101 + rows_ageM
    
    # Open an output file connection
    outfilename <- file(paste0("rates/",Country,"mort",year), "w")
    # without ".txt" specification as the original files had no format.
    
    # Include Country and year of the corresponding probabilities
    cat(c("** Period (Monthly) Age-Specific Probabilities of Death for", Country, "in", year, "\n"),
        file = outfilename)
    cat(c("* Retrieved from the World Population Prospects 2024. Single age life tables up to age 100 Medium variant", "\n"),
        file = outfilename)
    cat(c("* https://population.un.org/wpp/assets/Excel%20Files/1_Indicator%20(Standard)/CSV_FILES/WPP2024_Life_Table_Complete_Medium_Female_1950-2023.csv.gz", "and", "\n"),
        file = outfilename)
    cat(c("* https://population.un.org/wpp/assets/Excel%20Files/1_Indicator%20(Standard)/CSV_FILES/WPP2024_Life_Table_Complete_Medium_Male_1950-2023.csv.gz", "and", "\n"),
        file = outfilename)
    cat(c("* https://population.un.org/wpp/assets/Excel%20Files/1_Indicator%20(Standard)/CSV_FILES/WPP2024_Life_Table_Complete_Medium_Female_2024-2100.csv.gz", "and", "\n"),
        file = outfilename)
    cat(c("* https://population.un.org/wpp/assets/Excel%20Files/1_Indicator%20(Standard)/CSV_FILES/WPP2024_Life_Table_Complete_Medium_Male_2024-2100.csv.gz", "and", "\n"),
        file = outfilename)
    cat(c("* United Nations. Population Division. Department of Economic and Social Affairs", "\n"),
        file = outfilename)
    cat(c("* Data downloaded on ", format(Sys.time(), format= "%d %b %Y %X %Z"), "\n"),
        file = outfilename)
    cat(c("** NB: The original WPP annual probabilities have been converted into monthly probabilities", "\n"),
        file = outfilename)
    cat(c("** The final age interval is limited to one year [100-101)", "\n"),
        file = outfilename)
    cat("\n", file = outfilename)
    
    # Print mortality probabilities (single females)
    cat("death", "1", "F", "single", "\n", file = outfilename)
    for(i in n_row) {
      cat(c(as.matrix(ASMP)[i,-c(1,5)], "\n"), file = outfilename) }
    cat("\n", file = outfilename)
    
    # Print mortality probabilities (single males)
    cat("death", "1", "M", "single", "\n", file = outfilename)
    for(i in n_row) {
      cat(c(as.matrix(ASMP)[i,-c(1,4)], "\n"), file = outfilename) }
    
    close(outfilename)
    
  }
}