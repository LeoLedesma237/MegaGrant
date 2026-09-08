# MAIN SCRIPT
#
# The function of this script is to run several Rmarkdowns that each take the final analysis for Leo's
# Masters Thesis and compartmentalizes This was done to make the navigation of the document much easier.
# In addition, each segments will save their own information as .Rdata files, whichs makes working on one
# specific aspect of the code very convenient- instead of needing to run the full script. Lastly, we can
# also produce several .html files and skip running the code entirely by going to a specific one and looking
# at the output. A great advantage of being forced to print out the .html files is that it basically forces
# us to debug code as well and helps us organize what packages actually correspond to what part of the 
# analysis. Lastly, this approach substantially reduces the number of objects in the Environment- making
# it easier to tidy up code or stuff that matters.

# Set working directory 
setwd("~/GitHub/MegaGrant/Analyses/Final Masters Analysis")

#
### Run the Rmarkdown files
#

# IF ERROR PRODUCED RESTART- R!!!

# Number 1: Reading in All Datasets (Behavioral and EEG) and Correcting the IDs
rmarkdown::render(input = "1_Reading_All_Data_and_Correcting_IDs.Rmd", 
                  output_file = "html/1_Reading_All_Data_and_Correcting_IDs")

# Number 2: Exploring the ARFA and Running Psychometrics (GRM)
rmarkdown::render(input = "2_Exploring_ARFA_and_GRM.Rmd", 
                  output_file = "html/2_Exploring_ARFA_and_GRM")

# Number 3: Exploring the CFIT and Running Psychometrics (Bi-Factor & 2PL)
rmarkdown::render(input = "3_Exploring_CFIT_and_IRT.Rmd", 
                  output_file = "html/3_Exploring_CFIT_and_IRT")

# Number 4: Excluding Participants from the main Analysis 
rmarkdown::render(input = "4_Excluding_Participants.Rmd", 
                  output_file = "html/4_Excluding_Participants")

# Number 5: Creating Spelling Groups using A QTP Model
rmarkdown::render(input = "5_Creating_Spelling_Groups.Rmd", 
                  output_file = "html/5_Creating_Spelling_Groups")

# Number 6: EEG Data Exploration, Reduction, and Preparation for Analysis
rmarkdown::render(input = "6_EEG_Data_reduction_and_Exploration.Rmd", 
                  output_file = "html/6_EEG_Data_reduction_and_Exploration")

# Number 7: Fitting QTPME Models and Saving the Output
rmarkdown::render(input = "7_Fitting_QTPME_to_Age_and_rsEEG_by_Spelling.Rmd", 
                  output_file = "html/7_Fitting_QTPME_to_Age_and_rsEEG_by_Spellings")

# Number 8: Follow-up and Interpreting the QTPME Models
rmarkdown::render(input = "8_Follow_up_and_QTPME_interpretation.Rmd", 
                  output_file = "html/8_Follow_up_and_QTPME_interpretation")


