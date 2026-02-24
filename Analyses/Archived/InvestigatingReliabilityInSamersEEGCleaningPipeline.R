# Load in packages
library(tidyverse)
library(ggplot2)

# Aesthetics (Leo version)
theme_clean <- function() {
  theme_minimal() +
    theme(legend.position = "bottom",
          panel.grid.minor = element_blank(),
          plot.title = element_text(hjust = 0.5),
          strip.text = element_text(size = 15))
}


####
########## Part 1: Investigating Whether The Same Preprocessing Script Produces The Same Cleaning Outcomes
####

# Set working directory
setwd("~/MegaGrant/test/03_clearnrsEEG_30hz_reports")

# Load in all files
all_files <- list.files()
all_files_list <- list()

# Read in the data using a for loop
for(ii in 1:length(all_files)) {
  current_dat <-  read.csv(all_files[ii])
  current_dat$ID <- as.numeric(gsub("\\D", "", current_dat$FileName))
  all_files_list[[ii]] <-current_dat
}

# Bind the files (each is a row) into a data frame
all_files_df <- do.call(rbind, all_files_list)

# View average amp across cleaning iterations
avgAmp_df <- all_files_df %>%
  select(ID, starts_with("avgAmp"))

# Data Cleaning in Prepartion for plotting
avgAmp_df2 <- avgAmp_df %>%
  mutate(Iteration = rep(c(1:3), nrow(.)/3)) %>%
  pivot_longer(cols = c(avgAmpRange1:avgAmpRange7), 
               names_to = 'avgAmpType',
               values_to = 'avgAmp') %>%
  filter(avgAmpType != "avgAmpRange7") %>%
  mutate(ID2 = as.numeric(factor(ID)),
         Iteration = factor(Iteration),
         avgAmpType = factor(avgAmpType,
                             labels = c("Removed Unwated Channels", 
                                        "Band-Pass Filter",
                                        "Channel Interpolation",
                                        "Re-Referencing",
                                        "ICA Only",
                                        "Removed Artifact Components")))

# Plot the average amplitude range
avgAmp_df2 %>%
  ggplot(aes(x=ID2, y = avgAmp, color = Iteration)) +
  geom_point(size = 3, alpha = .5) +
  facet_wrap(~avgAmpType, scales = "free") +
  labs(x = "Subjet IDs", 
       y = "Average Amplitude Range (microVolts)",
       title = "Average Amplitude Range for the Same 20 Recordings After Automatic Preprocessing Steps\n") +
  theme_clean()



####
########## Part 2: Investigating Whether The Same Preprocessing Script Produces The Same Power Values
####


# Set working directory
setwd("~/MegaGrant/test/06_cleanrsEEG_30hz_Final_FFT_Welch_CSVs")

# Read in the data
QC_dat <- read.csv("EC_30Hz_topographyFBAvgPowWelch.csv")

# Data cleaning
QC_dat$Iteration <- as.numeric(gsub(".set", "", sapply(str_split(QC_dat$filename, "_"), function(x) x[5])))
QC_dat$ID <- as.numeric(gsub("\\D", "",sapply(str_split(QC_dat$filename, "_"), function(x) x[1])))
QC_dat <- select(QC_dat, - filename)

# Convert the dataset into long
str(QC_dat)
QC_datL <- QC_dat %>%
  pivot_longer(cols = c(frontal_absdelta:occipital_relbeta),
               names_to = "topo_pow_fb",
               values_to = "power") %>%
  mutate(
    topography = case_when(
      grepl("frontal", topo_pow_fb) ~ "frontal",
      grepl("temporal", topo_pow_fb) ~ "temporal",
      grepl("parietal", topo_pow_fb) ~ "parietal",
      grepl("occipital", topo_pow_fb) ~ "occipital"),
    
    power_type = case_when(
      grepl("abs", topo_pow_fb) ~ "abs",
      grepl("avg", topo_pow_fb) ~ "avg",
      grepl("rel", topo_pow_fb) ~ "rel"),
    
    frequency_band = case_when(
      grepl("delta", topo_pow_fb) ~ "delta",
      grepl("theta", topo_pow_fb) ~ "theta",
      grepl("alpha", topo_pow_fb) ~ "alpha",
      grepl("beta", topo_pow_fb) ~ "beta"))

# Plotting Absolute Power Graph
QC_datL %>%
  filter(power_type == "abs") %>%
  mutate(ID2 = as.numeric(factor(ID))) %>%
  ggplot(aes(x = ID2, y = power, color = Iteration)) +
  facet_grid2(frequency_band~topography, scales = "free") +
  geom_point(size = 3, alpha = .5) +
  labs(x = "Subjet IDs", 
       y = "Power (Amplitude^2)",
       title = "Power by Topography and Frequency Band for 20 Cleaned rsEEG Recordings \n") +
  theme_clean()
