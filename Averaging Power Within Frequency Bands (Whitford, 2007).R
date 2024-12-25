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
frontal = c("Fp1", "Fp2", "F7", "F3", "Fz", "F4", "F8", "FC3", "FCz", "FC4")
temporal = c("T7", "TP7", "T8", "TP8")
parietal = c("CP3", "CPz", "CP4", "P3", "Pz", "P4")
occipital = c("O1", "Oz", "O2")

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
  
  # Extract current element of FileNames
  current.File = FileNames[ii]
  
  # Practice read in a file
  data <- read.csv(current.File) %>% tibble()
  
  # Create an ID Variable
  data$ID <- as.numeric(gsub("\\D", "",current.File))
  
  # Create a condition variable
  data$Condition <- ifelse(grepl(pattern ="Closed", current.File), "Closed", "Open")
  
  # Make channels first in the dataset
  data <- select(data, ID, Channels, Condition, everything())
  
  # Convert frequency band parameters into variable names
  d1 <- paste("x", delta_start, sep ="")
  d2 <- paste("x", delta_stop, sep="")
  t1 <- paste("x", theta_start, sep ="")
  t2 <- paste("x", theta_stop, sep="")
  a1 <- paste("x", alpha_start, sep ="")
  a2 <- paste("x", alpha_stop, sep="")
  b1 <- paste("x", beta_start, sep ="")
  b2 <- paste("x", beta_stop, sep="")
  
  
  # Create a new dataset with calculated  frequency band power
  data$delta <- select(data, d1:d2) %>% rowMeans()
  data$theta <- select(data, t1:t2) %>% rowMeans()
  data$alpha <- select(data, a1:a2) %>% rowMeans()
  data$beta <- select(data, b1:b2) %>% rowMeans()
  
  # Add a topography variable
  data <- data %>%
    mutate(Topography = case_when(
      
      Channels %in% frontal ~ "frontal",
      Channels %in% temporal ~ "temporal",
      Channels %in% parietal ~ "parietal",
      Channels %in% occipital ~ "occipital",
      TRUE ~ "other"
    ))
  
  # Create a new dataset removing unneeded power columns
  FBP.df <- data.frame(
    ID = data$ID,
    Topography = data$Topography,
    Condition = data$Condition,
    delta = data$delta,
    theta= data$theta,
    alpha = data$alpha,
    beta = data$beta
    
  )
  
  # Remove topography from other
  FBP.df <- filter(FBP.df, Topography != "other")
  
  # Pbtain the means of topography x FB
  FBP.df.means <- FBP.df %>%
    group_by(ID, Condition, Topography) %>%
    summarise(Delta = mean(delta),
              Theta = mean(theta),
              Alpha = mean(alpha),
              Beta = mean(beta))
  
  # Transform the data to wide format
  FBP.wide <- FBP.df.means %>%
    pivot_wider(names_from = Topography, values_from = c(Delta, Theta, Alpha, Beta))
    
  # Rename the variables so Topography comes first
  Topography.names <- names(FBP.wide)[3:length(names(FBP.wide))]
  Topography <- lapply(str_split(Topography.names, "_"), function(x) x[2])
  FB <- lapply(str_split(Topography.names, "_"), function(x) x[1])
  new.names.df <- mutate(data.frame(cbind(Topography, FB)), new.names = paste(Topography,"_",FB, sep=""))
  new.names.df$new.names <- tolower(new.names.df$new.names)
  
  # Introduce the new names
  names(FBP.wide) <- c("ID", "Condition", new.names.df$new.names)
  
  # Change the order of the variables
  FBP.wide <- FBP.wide %>%
    select(ID, Condition, starts_with("frontal"), starts_with("temporal"), starts_with("parietal"), starts_with("occipita"))
  
   AllFiles.list[[ii]] <- FBP.wide
  
}



# Save it all into one dataset
both.conditions <- do.call(rbind, AllFiles.list)



# Split by conditions
eyes.closed <- filter(both.conditions, Condition == "Closed")
eyes.open <- filter(both.conditions, Condition == "Open")


# Save this information into an excel
setwd("C:/Users/lledesma.TIMES/Documents/MegaGrant")


write.xlsx(list(eyes.closed = eyes.closed,
                eyes.open = eyes.open),
           file = "Processed/EEGData/EEG Eyes Open and Closed FB Power (Whitford, 2007).xlsx")
