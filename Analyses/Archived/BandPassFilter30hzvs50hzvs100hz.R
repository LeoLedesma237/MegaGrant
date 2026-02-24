# Load in packages
library(tidyverse)
library(ggplot2)
library(patchwork)
library(readxl)

# Aesthetics (Leo version)
theme_clean <- function() {
  theme_minimal() +
    theme(legend.position = "bottom",
          panel.grid.minor = element_blank(),
          plot.title = element_text(hjust = 0.5),
          strip.text = element_text(size = 12))
}

####
########## Part 1: Investigating Whether Modifying the Band Pass Filter/Detrend Produced Different Cleaning Outcomes
####


# Set working directory 
setwd("~/MegaGrant/30hz_50hz_100hz_vs_DCOffset")

# Load in the QC main file
all_files_df <- read_excel('30hz_50hz_100hz_QC_reports.xlsx') %>% unique()

# Data cleaning
all_files_df <- all_files_df %>%
  mutate(BandPassFilt = gsub("5.000000e-01", "0.5", BandPassFilt),
         rmvDc = ifelse(removedDCOffset == "true", '; detrended', "; no"),
         group = paste0(BandPassFilt,"",rmvDc)) %>%
  data.frame()

# Add an ID variable
all_files_df$ID <- as.numeric(gsub("\\D", "" ,sapply(str_split(all_files_df$FileName, "_"), function(x) x[1])))

all_files_df <- all_files_df %>%
  mutate(ID2 = as.numeric(factor(ID)))

# Lets investigate differences in average amplitude range
avg_amp_range <- all_files_df %>%
  select(ID, group, BandPassFilt, rmvDc, starts_with("avgAmp")) %>%
  mutate(ID2 = as.numeric(factor(ID))) %>%
  arrange(ID)

# More data cleaning
avg_amp_range <- avg_amp_range %>%
  mutate(rmvDc  = gsub("; ","", rmvDc),
         BandPassFilt = factor(BandPassFilt, levels = c("0.5-30 Hz", "0.5-50 Hz", "0.5-100 Hz")))


# Get a feel for current sample size
xtabs(~ group, avg_amp_range)


# Make the dataset long
avg_amp_rangeL <- avg_amp_range %>%
  pivot_longer(cols = c(avgAmpRange1:avgAmpRange6), 
               names_to = 'avgAmpType',
               values_to = 'avgAmp') %>%
  mutate(avgAmpType = factor(avgAmpType,
                             labels = c("Removed Unwated\nChannels", 
                                        "Detrended",
                                        "Band-Pass Filter",
                                        "Channel Interpolation",
                                        "Re-Referencing",
                                        "Removed Artifact\nComponents")))
# Add a standardized measure of average amplitude range to remove outliers later
avg_amp_rangeL <- avg_amp_rangeL %>%
  group_by(avgAmpType) %>%
  mutate(avgAmp_z = c(scale(avgAmp)))


# Plot the differences in amplitude average (Main effects of Band-Pass Filter)
BandPass_plot <- avg_amp_rangeL %>%
  filter(avgAmp_z <3) %>%
  ggplot(aes(x = BandPassFilt, y = avgAmp, color = BandPassFilt)) +
  geom_boxplot(outliers = FALSE) +
  geom_jitter(width = .2, alpha = .6, size = 1.5) +
  facet_wrap(~avgAmpType, scales = "free") +
  labs(title = "Band-Pass Filter Effects on Average Amplitude Range\nat Different Preprocessing Steps",
       x = NULL,
       y = "Average Amplitude Range") +
  theme_clean()

# Plot the differences in amplitude average (Main effects of Detrending)
Detrend_plot <- avg_amp_rangeL %>%
  filter(avgAmp_z <3) %>%
  ggplot(aes(x = rmvDc, y = avgAmp, color = rmvDc)) +
  geom_boxplot(outliers = FALSE) +
  geom_jitter(width = .2, alpha = .6, size = 1.5) +
  facet_wrap(~avgAmpType, scales = "free") +
  labs(title = "Detrend Effects on Average Amplitude Range\nat Different Preprocessing Steps",
       x = NULL,
       y = "Average Amplitude Range") +
  theme_clean()


# Join the plots into one
BandPass_plot + Detrend_plot

# Plot the differences in amplitude average (Interactions)
BandPass_Detrend_plot <- 
  avg_amp_rangeL %>%
    filter(avgAmp_z <3) %>%
  ggplot(aes(group, y = avgAmp, color = group, shape = rmvDc)) +
    geom_boxplot(outliers = FALSE) +
    geom_jitter(width = .25, size = 1.5, alpha = .5) +
  facet_wrap(~avgAmpType, scales = "free") +
  labs(x = NULL, 
       y = "Average Amplitude Range (microVolts)",
       title = "Average Amplitude Range for the Same 8 Recordings After Automatic Preprocessing Steps\n") +
    coord_flip() +
    theme_clean() +
    theme(axis.text.y = element_blank()) +
    theme(axis.text.y = element_blank())

# Show the interaction between the two
BandPass_Detrend_plot


# Plot differences at channels interpolated (average)
chan_plot <- all_files_df %>%
  ggplot(aes(x= group, y = NumAllBadChannels, color = group)) +
  geom_boxplot(outliers = FALSE) +
  geom_jitter(width = .25, size = 1, alpha = .5) +
  labs(title = "Number of Bad Channels Interpolated\nBetween BandPass Approaches",
       x = NULL,
       y = "Number of Bad Channels Interpolated",
       color = NULL) +
  coord_flip() +
  theme_clean() +
  theme(axis.text.y = element_blank())

# plot differences at number of brain components by preprocessing pipelines
brainComp_plot <- all_files_df %>%
  ggplot(aes(x= group, y = TotalBrainComponents, color = group)) +
  geom_boxplot(outliers = FALSE) +
  geom_jitter(width = .25, size = 1, alpha = .5) +
  labs(title = "Number of Brain Components Identified\nBy Preprocessing Pipelines",
       x = NULL,
       y = "Number of Brain Components",
       color = NULL) +
  coord_flip() +
  theme_clean() +
  theme(axis.text.y = element_blank())

# plot differences in number of artifact components by preprocessing pipelines
ArtifactComp_plot <- all_files_df %>%
  ggplot(aes(x= group, y = ComponentsRemoved, color = group)) +
  geom_boxplot(outliers = FALSE) +
  geom_jitter(width = .25, size = 1, alpha = .5) +
  labs(title = "Number of Artifact Components Identified\nBy Preprocessing Pipelines",
       x = NULL,
       y = "Number of Artifact Components",
       color = NULL) +
  coord_flip() +
  theme_clean() +
  theme(axis.text.y = element_blank()) +
  theme(axis.text.y = element_blank())


# plot differences at number of brain components by preprocessing pipelines
goodSegProp_plot <- all_files_df %>%
  ggplot(aes(x= group, y = SegPropGood, color = group)) +
  geom_boxplot(outliers = FALSE) +
  geom_jitter(width = .25, size = 1, alpha = .5) +
  labs(title = "Proportion of Clean Segments\nBy Preprocessing Pipelines",
       x = NULL,
       y = "Number of Brain Components",
       color = NULL) +
  coord_flip() +
  theme_clean() +
  theme(axis.text.y = element_blank()) +
  theme(axis.text.y = element_blank())

# Generate plot with bad channels, brain components, and good segments
chan_plot + brainComp_plot + ArtifactComp_plot + goodSegProp_plot



####
########## Part 2: Investigating Whether The Same Preprocessing Script Produces The Same Power Values
####

# Set working directory to where the power data is saved
setwd("~/MegaGrant/30hz_50hz_100hz_vs_DCOffset/06_Final_Welch_CSVs")

# Read in the data
Pow_dat <- read.csv("30hz_50hz_100hz_topographyFBAvgPowWelch.csv")

# Creating new variables
Pow_dat$ID <- as.numeric(gsub("\\D", "",sapply(str_split(Pow_dat$filename, "_"), function(x) x[1])))
Pow_dat <- Pow_dat %>%
  mutate(
    BandPassFilt = case_when(
      grepl("30Hz",filename) ~ "0.5-30Hz",
      grepl("50Hz",filename) ~ "0.5-50Hz",
      grepl("100Hz",filename) ~ "0.5-100Hz"),
    
    rmvDc = case_when(
      grepl("detrend",filename) ~ "detrended",
      TRUE ~ "no"),
    
    group = case_when(
      grepl("30",filename) & grepl("detrend",filename) ~ "0.5-30Hz; detrended",
      grepl("30",filename) & !grepl("detrend",filename) ~ "0.5-30Hz",
      grepl("50",filename) & grepl("detrend",filename) ~ "0.5-50Hz; detrended",
      grepl("50",filename) & !grepl("detrend",filename) ~ "0.5-50Hz",
      grepl("100",filename) & grepl("detrend",filename) ~ "0.5-100Hz; detrended",
      grepl("100",filename) & !grepl("detrend",filename) ~ "0.5-100Hz",
      TRUE ~ "ERROR"))

# Remove 'filename' since it is no longer important
Pow_dat <- select(Pow_dat, - filename)

# Convert the dataset into long abd add EEG related variables
str(Pow_dat)
Pow_datL <- Pow_dat %>%
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

# Convert variables into factors for better plotting
Pow_datL <- Pow_datL %>%
  mutate(BandPassFilt = factor(BandPassFilt, 
                               levels = c("0.5-30Hz", "0.5-50Hz", "0.5-100Hz"),
                               labels = c("30Hz", "50Hz", "100Hz")),
         topography = factor(topography, levels = c("frontal", "temporal", "parietal", "occipital")),
         frequency_band = factor(frequency_band, levels = c("delta", "theta", "alpha", "beta")))


# Plotting main effects (Band Pass Filter effects on Absolute Power)
BandPass_Pow_plot <- Pow_datL %>%
  filter(power_type == "abs") %>%
  ggplot(aes(x = BandPassFilt, y = power, color = BandPassFilt)) +
  geom_boxplot(outliers = FALSE) +
  geom_jitter(width = .2, size = 1, alpha = .6) +
  ggh4x::facet_grid2(frequency_band~topography, scales = "free", independent = "all") +
  labs(x = NULL, 
       y = "Power (Amplitude^2)",
       title = "Absolute Power by Topography and Frequency Band For Three\nDifferent Band-Pass Filters",
       color = NULL) +
  theme_clean()
  
# Plotting main effects (Detrending effects on Absolute Power)
Detrend_Pow_plot <- Pow_datL %>%
  filter(power_type == "abs") %>%
  ggplot(aes(x = rmvDc, y = power, color = rmvDc)) +
  geom_boxplot(outliers = FALSE) +
  geom_jitter(width = .2, size = 1, alpha = .6) +
  ggh4x::facet_grid2(frequency_band~topography, scales = "free", independent = "all") +
  labs(x = NULL, 
       y = "Power (Amplitude^2)",
       title = "Absolute Power by Topography and Frequency Band For Three\nDifferent Low-Pass Filters",
       color = NULL) +
  theme_clean()

# Comprehensive Plot of Low Pass and Detrend Effects on Power
BandPass_Pow_plot + Detrend_Pow_plot

# Plotting Absolute Power Graph
Pow_datL %>%
  filter(power_type == "abs") %>%
  ggplot(aes(x = group, y = power, color = group)) +
  ggh4x::facet_grid2(frequency_band~topography, scales = "free", independent = "all") +
  geom_boxplot(outliers = FALSE) +
  geom_jitter(width = .25, size = 1, alpha = .5) +
  coord_flip() + 
  labs(x = "Subjet IDs", 
       y = "Power (Amplitude^2)",
       title = "Power by Topography and Frequency Band for 5 Cleaned rsEEG Recordings \n",
       color = NULL) +
  theme_clean() +
  theme(axis.text.y = element_blank()) +
  theme(axis.text.y = element_blank())

