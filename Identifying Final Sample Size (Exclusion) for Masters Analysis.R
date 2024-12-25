# Load in packages
library(tidyverse)
library(readxl)
library(openxlsx)

# Set working directory
setwd("Y:/STUDY 1")

# Load in the master data file
Master.dataset <- read_excel("MegaGrant_TBL_Database_Newest_MCh with duration.xlsx")

# Load in all of the files from S1
S1 <- Master.dataset %>%
  filter(`S1 reg-list` == "+")

nrow(S1)
sum(duplicated(S1$ID))
sum(is.na(S1$ID))

describe(S1$Age)

table(S1$Sex, useNA = "ifany")



# Load in the medical history questionnaire
setwd("Y:/STUDY 1/All Hand and Med Organized/Usable Med Excels")
Medical <- read_excel("TBL_WHOQOL_BRIEF_Medical_S1_S3_DM_06.xlsx",  sheet = "med s1")

# Select the variables of interest
Medical2 <- select(Medical, ID, HeadTrauma, Health2epilepsy, Health2autism)

# Create an exclusion variable
Medical2 <- Medical2 %>%
  mutate(Med.Excluded = case_when(
    HeadTrauma == "Y" | Health2epilepsy == "Y" | Health2autism == "Y" ~ "Y",
    TRUE ~ "N"
  ))

Medical.Excluded.IDs <- Medical2$ID[Medical2$Med.Excluded == "Y"]


# Remove the medical excluded IDs
S1 <- S1 %>%
  filter(!(ID %in% Medical.Excluded.IDs))



# Load in the master excel sheet that keeps track of available data
Master.Excel2 <- select(Master.dataset, ID, Age, Sex, ARFA, CFIT, RAW)

# Create a variable for missing data
Master.Excel2$Missing.Data <- rowSums(is.na(Master.Excel2))

Missing.Data.IDs <- Master.Excel2$ID[Master.Excel2$Missing.Data != 0]

# Remove the IDs missing data
S1 <- S1 %>%
  filter(!(ID %in% Missing.Data.IDs))


# Very low IQ
setwd("Y:/STUDY 1/All Behavioral Data Organized/Usable CFIT Excels")

CFIT <- read_excel("CFIT.xlsx")

# Select the variables of interest
CFIT2 <- select(CFIT, ID, Sub1Sum:Sub4Sum)

# Drop rows that have NA for any of the columns
CFIT2 <- drop_na(CFIT2)

# Calculate a raw score of correct responses
CFIT2<- mutate(CFIT2, Raw.Scores = Sub1Sum + Sub2Sum + Sub3Sum + Sub4Sum)

# Create a variable to Exclude those who 2 or more SD below the mean
CFIT2$mean.Raw.Scores <- mean(CFIT2$Raw.Scores)
CFIT2$SD.Raw.Scores <- sd(CFIT2$Raw.Scores)

CFIT2 <- mutate(CFIT2, Excluded = ifelse(Raw.Scores < mean.Raw.Scores - 2* SD.Raw.Scores, "Y", "N"))

Low.IQ.IDs <- CFIT2$ID[CFIT2$Excluded == "Y"]

# Keep the IDs with full data
S1 <- S1 %>%
  filter((ID %in% CFIT2$ID))

# Drop the IDs with Low IQ Scores
S1 <- S1 %>%
  filter(!(ID %in% Low.IQ.IDs))



# Extremely poor spellers
setwd("~/Masters Project/cleaned_predictor_covariates")

Spelling.Errors <- read.csv("ARFA.Spelling.Errors.Scored.csv")

sum(Spelling.Errors$Total_SpellingError_Z < -3)



# Had Issues with Marker information (aka do not have both rsEEG conditions)
setwd("Y:/STUDY 1/All EEG Files Organized/Preprocessed_RAW")

Both.Conditions <- read_excel("EEG Raw File Names.xlsx")

# Create an ID variable
Both.Conditions$ID <- as.numeric(gsub("\\D", "", Both.Conditions$file.name))

# Keep only the IDs that have both trigger codes
S1 <- S1 %>%
  filter(ID %in% Both.Conditions$ID)



# Did not survive EEG cleaning (Both Eyes Open and Eyes Closed)
setwd("Y:/STUDY 1/All EEG Files Organized/Preprocessed_RAW")

eyes.closed <- read_excel("EEG Raw File Names3 (ready for FFT).xlsx", sheet = "Cleaned.Closed")
eyes.open <- read_excel("EEG Raw File Names3 (ready for FFT).xlsx", sheet = "Cleaned.Open")

# Create and ID variable
eyes.closed$ID <- as.numeric(gsub("\\D", "", eyes.closed$FileName))
eyes.open$ID <- as.numeric(gsub("\\D", "", eyes.open$FileName))

# Keep only IDs that have at least 80% of their data remaining after cleaning
eyes.closed2 <- filter(eyes.closed, PercentRemaining >= 80)
eyes.open2 <- filter(eyes.open, PercentRemaining >= 80)

# Keep only variables that are shared between both eyes.open and eyes.closed conditions
eyes.closed2.df <- data.frame(ID = eyes.closed2$ID,
                              eyes.closed = "+") %>% tibble()

eyes.open2.df <- data.frame(ID = eyes.open2$ID,
                            eyes.open = "+") %>% tibble()

# Shared IDs by both conditions
Both.Coditions.Survived <- eyes.closed2.df %>%
  left_join(eyes.open2.df, by = "ID")


# Keep these IDs that have both recordings
S1 <- S1 %>%
  filter(ID %in% Both.Coditions.Survived$ID)


# Get the descriptives of the new final sample size
nrow(S1)
sum(duplicated(S1$ID))
sum(is.na(S1$ID))

describe(S1$Age)

table(S1$Sex, useNA = "ifany")


# Set working directory to save the dataset
setwd("C:/Users/lledesma.TIMES/Documents/Masters Project")

# Select Variables of Interest
S1.final <- select(S1, ID, `S1 reg-list`, Age, Sex, Group, ARFA, CFIT, RAW, Comments, Decision)

# Save S1
write.xlsx(list(N = S1.final), file = "Final.Sample.Size.xlsx")


# Quality Control
S1.final.2 <- select(S1.final, -c(Comments, Decision))
          
S1.final.2 %>%
  filter(!complete.cases(.))
