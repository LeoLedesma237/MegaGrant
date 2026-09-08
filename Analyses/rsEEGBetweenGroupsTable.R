# Generating a nice table showcasing rsEEG results between good and poor reading/spelling/writing children and adults
# This code is fully functional in Lisa's PC!

# Load in packages
library(tidyverse)
library(kableExtra)

# Set working directory
setwd("~/MegaGrant")

# Load in the data
final_df <- read_excel("rsEEGBetweenGroupsTable.xlsx")

# Extracting variables that need multiple rows
df_rows <- select(final_df, Study:Occipital)

# Identify column positions
study_position      <- which(names(final_df) == "Study")
long_text_positions <- (ncol(df_rows) + 1):ncol(final_df)
collapse_cols       <- c(study_position, long_text_positions)

# Build the table
final_df %>%
  kbl(escape = FALSE, align = "l") %>%
  kable_styling(
    bootstrap_options = c("striped", "hover", "condensed"),
    font_size = 10,
    full_width = FALSE
  ) %>%
  column_spec(
    long_text_positions,
    width     = "32em",
    extra_css = "min-width: 28em; word-break: break-word; white-space: normal; line-height: 1.5;"
  ) %>%
  collapse_rows(
    columns = collapse_cols,
    valign  = "top"
  )




# Load in packages
library(tidyverse)
library(kableExtra)
library(readxl)

# Set working directory
setwd("~/MegaGrant")

# Load in the data
final_df <- read_excel("rsEEGBetweenGroupsTable.xlsx")

# Extracting variables that need multiple rows
df_rows <- select(final_df, Study:Occipital)

# Identify the variables that will have long text
long_text_cols <- names(final_df)[(ncol(df_rows) + 1):ncol(final_df)]

final_df <- final_df %>%
  group_by(Study) %>%
  fill(all_of(long_text_cols), .direction = "down") %>%
  ungroup()
# ─────────────────────────────────────────────────────────────────────────────

# Identify column positions
study_position      <- which(names(final_df) == "Study")
long_text_positions <- (ncol(df_rows) + 1):ncol(final_df)
collapse_cols       <- c(study_position, long_text_positions)

# Positions of the non-long-text columns
short_col_positions <- 1:(ncol(df_rows))


# Build the table
final_df %>%
  kbl(escape = FALSE, align = "l") %>%
  kable_styling(
    bootstrap_options = c("striped", "hover", "condensed"),
    font_size = 12,
    full_width = FALSE
  ) %>%
  # Size of the variable names
  row_spec(
    0,
    font_size = 12,    # adjust to taste
    bold      = TRUE   # optional, makes headers stand out more
  ) %>%
  # Control width of non-long text variables
  column_spec(
    short_col_positions,
    width     = "8em",
    extra_css = "min-width: 6em;"
  ) %>%
  column_spec(
    long_text_positions,
    width     = "28em",
    extra_css = "min-width: 24em; word-break: break-word; white-space: normal; line-height: 1.5; font-size: 14px;"
  ) %>%
  collapse_rows(
    columns = collapse_cols,
    valign  = "top"
  )
