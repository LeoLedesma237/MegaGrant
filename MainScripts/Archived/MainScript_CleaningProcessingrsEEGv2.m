% READ ME: This MainScript only works if you have the EEG wiki
% available on your computer with the custom made functions to
% clean and process rsEEG data. 


%%%%%%%%%%%%%%%%%%%% CONFIGURATION NEEDED %%%%%%%%%%%%%%%%%%%%%
% Set a MegaGrant pathway (saved locally for processing efficiency)
Mega = 'C:\Users\lledesma\Documents\';

% Set pathway to run EEGLAB
EEGLAB_Path = 'C:\Users\lledesma\Documents\MATLAB\eeglab2024.2';
addpath(EEGLAB_Path)
eeglab

% Set Pathway to EEG Functions
EEGFUN_path = append(Mega, 'GitHub\EEG\EEG_Cleaning\wet_rsEEG');
EEGFUN2_path = append(Mega, 'GitHub\EEG\generalfun');
EEGFUN3_path = append(Mega, 'GitHub\MegaGrant\EEGPreprocessing'); % wetrsEEGParameters
addpath(EEGFUN_path)
addpath(EEGFUN2_path)
addpath(EEGFUN3_path)


%%%%%%%%%%%%%%%%%%%% SET UP PARALLEL PROCESSING %%%%%%%%%%%%%%%%
% Obtain the number of available cores
numCores = feature('numcores');
disp(['Number of available cores: ', num2str(numCores)]);

% Start the recruting these cores
%parpool(numCores); 


% Generate a for loop to clean and process the rsEEG data in 6 different
% ways


%%%%%%%%%%%%%%%%%%%%%%%% Clean the rsEEG data %%%%%%%%%%%%%%%%%%%%%%%
% This will need to be remodified after testing is concluded
% Load in the wet-EEG preprocessing parameters
WetrsEEGParameters_Final % Loads in 'preprocParams'

% Location of the sub folder where all processed data will be saved
% (name of the analysis)
folder = 'Data';

% Set up pathways 
EEG_Raw_Pathway = append(Mega, 'MegaGrant\01_Eyes_Open_Eyes_Closed_Separated\');
EEG_Clean_Pathway = append(Mega, 'MegaGrant\',folder,'\02_clean_rsEEG\');
EEG_CSV_Save_Pathway = append(Mega, 'MegaGrant\',folder,'\03_clean_rsEEG_report\');
batchSize = 18; 

% Generate the folders (if they already exists then nothing happens)
mkdir(EEG_Clean_Pathway);
mkdir(EEG_CSV_Save_Pathway);

% Load in .set files in the Raw folder
eegFiles = load_EEG_names(EEG_Raw_Pathway,'.set','no');

% DELETE ME LATER (ONLY DOING EYES OPEN RIGHT NOW)
%eegFiles = eegFiles(contains(eegFiles, 'Open', 'IgnoreCase', true));

% Load in already processed files and remove them from eegFiles
processed_eegFiles = load_EEG_names(EEG_Clean_Pathway,'.set','no');
eegFiles = eegFiles(~ismember(eegFiles, replace(processed_eegFiles, preprocParams.fileExtEeg,'.set')));

% Run the rsEEG cleaning code
clean_wet_rseeg2(eegFiles, ...
        EEG_Raw_Pathway, ...
        EEG_Clean_Pathway , ...
        EEG_CSV_Save_Pathway, ...
        preprocParams, ...
        batchSize)



%%%%%%%%%%%%% Combining Individual Reports into Main Ones %%%%%%%%%%%%%%%%%%
% Fix the code 
% Create an array to store the main_QC_Dry_name
main_QC_dry_name = {};

% Setting pathways to where reports are saved for each task 
main_QC_dry_name = append(Mega, 'MegaGrant\',folder, '\comprehensiveQC_reports.xlsx');

% Organize the EEG QC reports
T1 = organizing_QC(EEG_CSV_Save_Pathway, '.csv');
T2 = struct2log(preprocParams);

% Save the table as an Excel file
writetable(T1, main_QC_dry_name);
writecell(T2, main_QC_dry_name, 'Sheet', 'Sheet2');

    
%%%%%%%%%%%%%%%%%%%%%%% Running Welch %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Runs custom welch function on clean EEG data
% Save the information into a separate directory (creates it if not
% available)

% Set up pathways 
EEG_Clean_Pathway = EEG_Clean_Pathway;  
EEG_Welch_Pathway = append(Mega, 'MegaGrant\',folder,'\04_Welch_Outcomes\');
EEG_Plot_Pathway = append(Mega, 'MegaGrant\',folder,'\05_Spectrum_Data_for_Plotting\');

% Set up more parameters for extract_eeg_freqband_power_welchx
bands = {'delta', 'theta', 'alpha', 'beta'};  
frexvc = [1, 4; 4, 8; 8, 13; 13, 30];  % [start, end] Hz for each band
setfiles = dir(fullfile(EEG_Clean_Pathway, '*.set'));  
filenames = {setfiles.name};
filenames = filenames(~contains(filenames, 'ICA')); % Remove ICA .set files
winsec = preprocParams.badSegsec; % time window (seconds)
nOverlap_per = preprocParams.badSegOverlp; % time window overlap (percentage)
outputname = '_struct_welchx2.mat';

% Generate the folders (if they already exists then nothing happens)
mkdir(EEG_Welch_Pathway);
mkdir(EEG_Plot_Pathway);

% Run FPpowelchx - will create structs with welchx2 output for all files
extract_eeg_freqband_power_welchx(bands, frexvc, EEG_Clean_Pathway, filenames, ...
    winsec, nOverlap_per, EEG_Welch_Pathway, EEG_Plot_Pathway, outputname, preprocParams)


%%%%%%%%% Creating topography x frequency band output table (Wide .csv) %%%%%%%%%%

% Load all Welch method .mat files
EEG_Welch_Pathway = EEG_Welch_Pathway;
EEG_Final_Welch_Pathway = append(Mega, 'MegaGrant\',folder,'\06_Final_Welch_CSVs\');
final_outputname = 'topographyFBAvgPowWelch.csv'; 

% Load in all saved .\mat files
matfiles = dir(fullfile(EEG_Welch_Pathway, '*welchx2.mat'));
awelchx = loadStructs2(EEG_Welch_Pathway, matfiles);

% Following Whitford 2007
% Must manually introduce what topography and channels to average by
nbchanstruct = struct();
nbchanstruct.frontal = {'Fp1', 'Fp2', 'F7', 'F3', 'Fz', 'F4', 'F8', 'FC3', 'FCz', 'FC4'};
nbchanstruct.temporal = {'T7', 'TP7', 'T8', 'TP8'};
nbchanstruct.parietal = {'CP3', 'CPz', 'CP4', 'P3', 'Pz', 'P4'};
nbchanstruct.occipital = {'O1', 'Oz', 'O2'};

% Frequency bands that we are interested in
FB_spectral_properties = {'absdelta', 'abstheta', 'absalpha', 'absbeta',...
                          'avgdelta', 'avgtheta', 'avgalpha', 'avgbeta',...
                          'reldelta', 'reltheta', 'relalpha', 'relbeta'};

% Generate the folders (if they already exists then nothing happens)
mkdir(EEG_Final_Welch_Pathway)

% Obtain a table with avg power for frequency bands and topography
topographyFBAvgPowWelch = topoFBpow(awelchx, nbchanstruct, FB_spectral_properties);

% Save the FFT and Welch Output
writetable(topographyFBAvgPowWelch, append(EEG_Final_Welch_Pathway, final_outputname));


%%%%%%%%% Saving Absolute Power From Specified FB for Each Electrode %%%%%%%%%%%

% Load in all saved .\mat files
matfiles = dir(fullfile(EEG_Welch_Pathway, '*welchx2.mat'));
awelchx = loadStructs2(EEG_Welch_Pathway, matfiles);

% Create a save pathway
csvSavePathway = append(Mega, 'MegaGrant\', folder,'\07_Final_Welch_Elc_CSVs\');

% Generate the folders (if they already exists then nothing happens)
mkdir(csvSavePathway);

% Save absolute power for each electrode
FBpow(awelchx, csvSavePathway);

