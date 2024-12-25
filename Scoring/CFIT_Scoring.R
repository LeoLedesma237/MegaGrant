library(tidyverse)
library(readxl)

# Set the working directory
setwd("Y:/STUDY 1/All Behavioral Data Organized/Usable CFIT Excels")

# Load the data
CFIT <- read_excel("Y:/STUDY 1/All Behavioral Data Organized/Usable CFIT Excels/CFIT.xlsx")

# Calculate the raw scores
CFIT <- CFIT %>%
  mutate(Raw.Scores = Sub1Sum + Sub2Sum + Sub3Sum + Sub4Sum)

# Set the save directory
setwd("C:/Users/lledesma.TIMES/Documents/Masters Project/cleaned_predictor_covariates")

# Save the data
write_csv("CFIT.scores.csv", x = CFIT)

