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


%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% 50 Hz
%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%% Clean the rsEEG data %%%%%%%%%%%%%%%%%%%%%%%
% This will need to be remodified after testing is concluded
% Load in the wet-EEG preprocessing parameters
WetrsEEGParameters_50Hz % 30Hz data should already exist!

% Set up pathways 
EEG_Pathway = append(Mega, 'MegaGrant\01_Eyes_Open_Eyes_Closed_Separated\');
EEG_save_path = append(Mega, 'MegaGrant\test\02_cleanrsEEG_50hz\');
EEG_csv_save_path = append(Mega, 'MegaGrant\test\03_clearnrsEEG_50hz_reports');
batchSize = 20; 

% Generate the folders (if they already exists then nothing happens)
mkdir(EEG_save_path);
mkdir(EEG_csv_save_path);

% Load in .set files in the Raw folder
eegFiles = load_EEG_names(EEG_Pathway,'.set','no');

% DELETE ME LATER (PICK FIRST 20 FILES)
eegFiles = eegFiles(1:20);

% Load in already processed files and remove them from eegFiles
%processed_eegFiles = load_EEG_names(EEG_save_path,'.set','no');
%eegFiles = eegFiles(~ismember(eegFiles, replace(processed_eegFiles, '_cleaned_dry.set','.vhdr')));

% Run the rsEEG cleaning code
clean_wet_rseeg2(eegFiles, ...
        EEG_Pathway, ...
        EEG_save_path , ...
        EEG_csv_save_path, ...
        preprocParams, ...
        batchSize)


%%%%%%%%%%%%%%%%%%%%%%% Running Welch %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Runs custom welch function on clean EEG data
% Save the information into a separate directory (creates it if not
% available)

% Set directories to where the cleaned rsEEG data is (from above)
% cleanrsEEGDir

% Set up pathways 
inputdir = append(Mega, 'MegaGrant\test\02_cleanrsEEG_50hz\');  
outputdir = append(Mega, 'MegaGrant\test\04_cleanrsEEG_50hz_Welch_Outcomes\');
outputdir2 = append(Mega, 'MegaGrant\test\05_cleanrsEEG_50hz_Spectrum_Data_for_Plotting\');

% Set up more parameters for extract_eeg_freqband_power_welchx
bands = {'delta', 'theta', 'alpha', 'beta'};  
frexvc = [1, 4; 4, 8; 8, 13; 13, 30];  % [start, end] Hz for each band
setfiles = dir(fullfile(inputdir, '*.set'));  
filenames = {setfiles.name};
filenames = filenames(~contains(filenames, 'ICA')); % Remove ICA .set files
winsec = 2;
nOverlap_per = 50;
outputname = "_50hz_struct_welchx2.mat";

% Generate the folders (if they already exists then nothing happens)
mkdir(outputdir);
mkdir(outputdir2);

% Run FPpowelchx - will create structs with welchx2 output for all files
extract_eeg_freqband_power_welchx(bands, frexvc, inputdir, filenames, winsec, nOverlap_per, outputdir, outputdir2, outputname)


%%%%%%%%% Creating topography x frequency band output table (Wide .csv) %%%%%%%%%%

% Load all Welch method .mat files
inputdir = append(Mega, 'MegaGrant\test\04_cleanrsEEG_50hz_Welch_Outcomes\');
outputdir = append(Mega, 'MegaGrant\test\06_cleanrsEEG_50hz_Final_FFT_Welch_CSVs\');
filename = 'EC_50hz_topographyFBAvgPowWelch.csv';

% Load in all saved .\mat files
matfiles = dir(fullfile(inputdir, '*welchx2.mat'));
awelchx = loadStructs2(inputdir, matfiles);

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
mkdir(outputdir)

% Obtain a table with avg power for frequency bands and topography
topographyFBAvgPowWelch = topoFBpow(awelchx, nbchanstruct, FB_spectral_properties);

% Save the FFT and Welch Output
writetable(topographyFBAvgPowWelch, append(outputdir, filename));


%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% 100 Hz
%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%% Clean the rsEEG data %%%%%%%%%%%%%%%%%%%%%%%
% This will need to be remodified after testing is concluded
% Load in the wet-EEG preprocessing parameters
WetrsEEGParameters_100Hz % 30Hz data should already exist!

% Set up pathways 
EEG_Pathway = append(Mega, 'MegaGrant\01_Eyes_Open_Eyes_Closed_Separated\');
EEG_save_path = append(Mega, 'MegaGrant\test\02_cleanrsEEG_100hz\');
EEG_csv_save_path = append(Mega, 'MegaGrant\test\03_clearnrsEEG_100hz_reports');
batchSize = 20; 

% Generate the folders (if they already exists then nothing happens)
mkdir(EEG_save_path);
mkdir(EEG_csv_save_path);

% Load in .set files in the Raw folder
eegFiles = load_EEG_names(EEG_Pathway,'.set','no');

% DELETE ME LATER (PICK FIRST 20 FILES)
eegFiles = eegFiles(1:20);

% Load in already processed files and remove them from eegFiles
%processed_eegFiles = load_EEG_names(EEG_save_path,'.set','no');
%eegFiles = eegFiles(~ismember(eegFiles, replace(processed_eegFiles, '_cleaned_dry.set','.vhdr')));

% Run the rsEEG cleaning code
clean_wet_rseeg2(eegFiles, ...
        EEG_Pathway, ...
        EEG_save_path , ...
        EEG_csv_save_path, ...
        preprocParams, ...
        batchSize)


