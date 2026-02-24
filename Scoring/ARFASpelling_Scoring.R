# This script is scoring ARFA spelling errors by maxing error numbers to 2
# Additionally a graded IRT model will be used to estimate theta values that measure spelling errors
# This is because at least three values can be present for each item

# UPDATE:
# Changes were made to the following code. Originally NA's were changed to 1 error?? I have no idea why I did that,
# this time they will be kept as NAs. I think the logic was that when I turned variables into numeric,
# a lot of cells would turn to NAs because those cells had words within them. So while I think that aspect is
# correct, I think we need to modify the code to prevent real NA's from being turned into an error.


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

# Aesthetics (Leo version)
theme_clean <- function() {
  theme_minimal() +
    theme(legend.position = "bottom",
          panel.grid.minor = element_blank(),
          plot.title = element_text(hjust = 0.5))
}   
          

# Items Spelling Error list
Items.Spelling.Error <- list()

# Extract the variables that will be used for scoring
Items <- paste("SP",1:22,".",sep = "")

# Create a list for quality control to keep track of how many types of errors (columns) were extracted for each item
item_error_var <- list()

# Create a function to be used within the for loop (converts words to NAs and then 1 but leaves real NAs alone)
clean_to_numeric_keep_real_na <- function(x) {
  # If already numeric → return as is
  if (is.numeric(x)) {
    return(x)
  }
  
  # Handle factor → character
  if (is.factor(x)) {
    x <- as.character(x)
  }
  
  # Replace empty strings / pure whitespace with NA
  x[x == "" | grepl("^\\s+$", x)] <- NA_character_
  
  # Attempt numeric conversion
  x_num <- suppressWarnings(as.numeric(x))
  
  # Where it became NA *because of non-numeric content* (not original NA) → set to 1
  is_coerced_na <- is.na(x_num) & !is.na(x)
  x_num[is_coerced_na] <- 1
  
  # Return numeric vector (real NAs stay NA)
  x_num
}

for(ii in 1:22) {
  
  # Save the current item names
  currnt_item <- Items[[ii]]
  
  # Extract all scoring variables for that item
  current.spelling.errors.num.df <- ARFA.spelling %>%
    select(starts_with(currnt_item))
  
  # Track the number of error variables corresponding to one item were extracted
  item_error_var[[ii]] <- ncol(current.spelling.errors.num.df)
  
  # Print the number of NAs by variable
  sapply(current.spelling.errors.num.df, function(x) sum(is.na(x)))
  
  # Convert everything in the dataset into a numeric number while keeping NA information
  current.spelling.errors.num.df <- current.spelling.errors.num.df %>%
    mutate(across(everything(), clean_to_numeric_keep_real_na))
  
  # Confirm NA structure remained the same
  sapply(current.spelling.errors.num.df, function(x) sum(is.na(x)))
  
  # Rename the variable
  names(current.spelling.errors.num.df) <- c("Spelling_Error")
  
  # Calculate the row sum
  item_error <- rowSums(current.spelling.errors.num.df, na.rm = T)
  
  # Cap error to not be larger than 2
  item_error_cap <- ifelse(item_error > 2, 2, item_error)
  
  # Check the distribution
  xtabs(~item_error_cap)
  
  # Save this into a list
  Items.Spelling.Error[[ii]] <- item_error_cap

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
error_counts <- sapply(ARFA_Items, function(x) table(x))

# Generate a plot
as.data.frame.matrix(t(error_counts)) %>%
  mutate(Items = 1:nrow(.),
         Items = factor(Items, levels = c("22","21","20","19","18","17","16","15","14","13","12",
                                          "11", "10", "9", "8", "7", "6", "5", "4","3","2","1")),
         Total = rowSums(select(., `0`:`2`))) %>%  # Calculate total frequency per item
  pivot_longer(cols = c(`0`:`2`),
               names_to = "Item Error Score",
               values_to = "Frequency") %>%
  mutate(Proportion = Frequency / Total) %>%  # Calculate proportion
  ggplot(aes(x = Items, y = Proportion, fill = `Item Error Score`)) +  # Use Proportion instead of Frequency
  geom_bar(stat = "identity") +
  scale_fill_brewer(palette = "Paired") +
  labs(title = "Proportion of Error Score by Item") +
  theme_clean() +
  coord_flip()

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
write_csv(cbind(ID = ARFA.spelling$ID, Items.Spelling.Error.Binded), file = "ARFA.Spelling.Raw.Scores.csv")