library(readxl)
library(tidyverse)

# Set the working directory
setwd("~/MegaGrant/ARFA Spelling Mistakes")

# load in the ARFA data that is unscored
ARFA.spelling <- read_excel("ARFA_Spelling_mistakes.xlsx")


# Items Spelling Error list
Items.Spelling.Error <- list()

# Extract the variables that will be used for scoring
Items <- paste("SP",1:22,".1",sep = "")


for(ii in 1:22) {

  # Extract all scoring variables for that item
  current.spelling.errors.df <- ARFA.spelling %>%
    select(starts_with(Items[[ii]]))
  
  # Convert everything in this dataset into a numeric value
  current.spelling.errors.num.df <- data.frame(sapply(current.spelling.errors.df, as.numeric))
  
  # Convert any NA's into 1's
  current.spelling.errors.num.df[is.na(current.spelling.errors.num.df)] <- 1
  
  # Rename the variable
  names(current.spelling.errors.num.df) <- c("Spelling_Error")
  
  # Get the Spelling Error for the item
  current.spelling.errors.num.df <- current.spelling.errors.num.df %>%
    mutate(Spelling_Error = case_when(
      Spelling_Error == 0 ~ 0,
      Spelling_Error == 1 ~ 1,
      Spelling_Error >= 2 ~ 2
    ))
  
  
  # Save this into a list
  Items.Spelling.Error[[ii]] <- current.spelling.errors.num.df$Spelling_Error

}



# Bind these scores into one dataset
Items.Spelling.Error.Binded <- data.frame(do.call(cbind, Items.Spelling.Error))

# Rename them
names(Items.Spelling.Error.Binded) <- paste("Item",1:22,"_SpellingError",sep="")

# Calculate the Row.Sum for a composite score
Items.Spelling.Error.Binded$Total_SpellingError <- rowSums(Items.Spelling.Error.Binded)


# Reintroduce this information into the original dataset
ARFA.spelling.scored <- cbind(ARFA.spelling,
                              Items.Spelling.Error.Binded) %>%
  tibble()

# Introduce Z scores into the dataset
ARFA.spelling.scored$Total_SpellingError_Z <- c(scale(ARFA.spelling.scored$Total_SpellingError))

# Save those whose errors was more than 2SD away from the mean
ARFA.spelling.scored.2SD <- ARFA.spelling.scored %>%
  filter(Total_SpellingError_Z >= 2)


# Set the working directory to save our data
setwd("~/Masters Project/cleaned_predictor_covariates")

# Save the version of Spelling Performance
write_csv(ARFA.spelling.scored, file = "ARFA.Spelling.Errors.Scored.csv")

# Save the tweaked version of Spelling performance
write.xlsx(ARFA.spelling.scored.2SD, file = "ARFA.Spelling.Errors.Scored.2SD.xlsx")


