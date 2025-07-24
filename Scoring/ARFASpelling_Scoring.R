# This script is scoring ARFA spelling errors by maxing error numbers to 2
# Additionally a graded IRT model will be used to estimate theta values that measure spelling errors
# This is because at least three values can be present for each item

# Load in Packages
library(readxl)
library(tidyverse)
library(mirt)
library(purrr)

# Set the working directory
setwd("Y:/RAW_DATA/Behavior/Usable ARFA Excels")

# load in the ARFA data that is unscored
ARFA.spelling <- read_excel("ARFA_Spelling_mistakes.xlsx")


###########                                   #############
########### THE REST OF THE CODE IS AUTOMATIC #############
###########  


#####
######## Part 1: Scoring Error By Recommendations from Russian Colleagues
#####


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

#######
############# Part 2: Graded Response Model
#######

# Save the items into their own dataset
ARFA_Items <- ARFA.spelling.scored %>%
  select(Item1_SpellingError:Item22_SpellingError)

# Count the total number of unique responses for each item
sapply(ARFA_Items, function(x) table(x))

# Specify the model
mod <- paste0("F = 1-",length(ARFA_Items))

# Count the number of unique value  for each item (ignore na's)
item_values <- do.call(c, map(ARFA_Items, ~ length(unique(na.omit(.x)))))

# Generate the item types vector
item_types <- ifelse(item_values == 1, "Remove", 
                     ifelse(item_values == 2, "2PL" ,"graded"))

# Run the mirt model and produce the theta scores
fit_mirt <- mirt(ARFA_Items, model = mod, itemtype = item_types, SE = TRUE, technical = list(NCYCLES = 20000))
ARFA.spelling.scored$theta <- c(fscores(fit_mirt, method = "EAP"))

# Obtain the correlation
cor(ARFA.spelling.scored$Total_SpellingError, 
    ARFA.spelling.scored$theta)

# Set the working directory to save our data
setwd("Y:/FINAL_DS/ARFA")

# Save the version of Spelling Performance
write_csv(ARFA.spelling.scored, file = "ARFA.Spelling.Errors.Scored.csv")