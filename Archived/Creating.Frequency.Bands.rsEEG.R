# Set parameters for frequency bands 
delta_start = 0.5
delta_stop = 3.75
theta_start = 4
theta_stop = 7.75
alpha_start = 8
alpha_stop = 12.75
beta_start = 13
beta_stop = 30

# Set the paramets for the channels
frontal = c("Fp1", "AF7", "AF3", "Fz", "Fp2", "AF4", "AF8")
temporal = c("FT9", "FT7", "T7", "TP7", "FT10", "FT8", "T8", "TP8")
central =  c("C3", "C1", "Cz", "CP3", "CP1", "CPz", "C2", "C4", "CP2", "CP4")
parietal = c( "P1", "P3", "Pz" ,"CP2", "P2", "P4")
occipital = c("PO3", "POz", "PO4", "O1", "Oz", "O2")

# Everything that follows is automatic

# Load in packaged
library(tidyverse)
library(readr)
library(openxlsx)

# Set working directory
setwd("Y:/STUDY 1/All EEG Files Organized/Preprocessed_RAW/CSV_eyes open and eyes closed FFT/Power")

# Extract all the file names
FileNames = list.files()

# Create an empty list to save all processed files to
AllFiles.list <- list()

for(ii in 1:length(FileNames)) {
  ii = 1
  # Extract current element of FileNames
  current.File = FileNames[ii]
  
  # Practice read in a file
  data <- read.csv(current.File) %>% tibble()
  
  # Create an ID Variable
  data$ID <- as.numeric(gsub("\\D", "",current.File))
  
  # Create a condition variable
  data$Condition <- ifelse(grepl(pattern ="Closed", current.File), "Closed", "Open")
  
  # Make channels first in the dataset
  data <- select(data, ID, Channels, everything())
  
  # Convert frequency band parameters into variable names
  d1 <- paste("x", delta_start, sep ="")
  d2 <- paste("x", delta_stop, sep="")
  t1 <- paste("x", theta_start, sep ="")
  t2 <- paste("x", theta_stop, sep="")
  a1 <- paste("x", alpha_start, sep ="")
  a2 <- paste("x", alpha_stop, sep="")
  b1 <- paste("x", beta_start, sep ="")
  b2 <- paste("x", beta_stop, sep="")
  
  
  # Calculate the frequency band power
  data$delta <- select(data, d1:d2) %>% rowMeans()
  data$theta <- select(data, t1:t2) %>% rowMeans()
  data$alpha <- select(data, a1:a2) %>% rowMeans()
  data$beta <- select(data, b1:b2) %>% rowMeans()
    
  # Add a topography variable
  data <- data %>%
    mutate(Topography = case_when(
      
      Channels %in% frontal ~ "frontal",
      Channels %in% central ~ "central",
      Channels %in% temporal ~ "temporal",
      Channels %in% parietal ~ "parietal",
      Channels %in% occipital ~ "occipital",
      TRUE ~ "other"
    ))
  
  
  # Summarize the data
  AllFiles.list[[ii]] <- data %>%
    group_by(ID, Condition, Topography) %>%
    summarise(Delta = mean(delta),
              Theta = mean(theta),
              Alpha = mean(alpha),
              Beta = mean(beta))
  
  }


# Save it all into one dataset
both.conditions <- do.call(rbind, AllFiles.list)

# Split by conditions
eyes.closed <- filter(both.conditions, Condition == "Closed")
eyes.open <- filter(both.conditions, Condition == "Open")


# Introduce variables identifying outliers in power within topographical location
eyes.closed <- eyes.closed %>%
  group_by(Topography) %>%
  mutate(Delta.z = (Delta - mean(Delta))/sd(Delta),
         Theta.z = (Theta - mean(Theta))/sd(Theta),
         Alpha.z = (Alpha - mean(Alpha))/sd(Alpha),
         Beta.z = (Beta - mean(Beta))/sd(Beta),
         
         Exclusion = case_when(
           abs(Delta.z) >= 3 | abs(Theta.z) >=3 | abs(Alpha.z) >=3 | abs(Beta.z) >= 3 ~ "Y",
           TRUE ~ "N"
         ))

eyes.open <- eyes.open %>%
  group_by(Topography) %>%
  mutate(Delta.z = (Delta - mean(Delta))/sd(Delta),
         Theta.z = (Theta - mean(Theta))/sd(Theta),
         Alpha.z = (Alpha - mean(Alpha))/sd(Alpha),
         Beta.z = (Beta - mean(Beta))/sd(Beta),
         
         Exclusion = case_when(
           abs(Delta.z) >= 3 | abs(Theta.z) >=3 | abs(Alpha.z) >=3 | abs(Beta.z) >= 3 ~ "Y",
           TRUE ~ "N"
         ))


# Save this information into an excel
setwd("C:/Users/lledesma.TIMES/Documents/Masters Project/cleaned_dependent_variable")

write.xlsx(list(eyes.closed = eyes.closed,
                eyes.open = eyes.open),
           file = "EEG Eyes Open and Closed FB Power.xlsx")
