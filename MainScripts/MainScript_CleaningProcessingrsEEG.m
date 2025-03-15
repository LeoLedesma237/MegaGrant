% READ ME: This MainScript only works if you have the EEG wiki
% available on your computer with the custom made functions to
% clean and process rsEEG data. 

% Typically I would have all pathways at the top of the document-
% but I think it be better to have them by section instead. 


%%%%%%%%%%%%%%%%%%%% CONFIGURATION NEEDED %%%%%%%%%%%%%%%%%%%%5
% Set pathway to run EEGLAB
EEGLAB_Path = 'C:\Users\lledesma\Documents\MATLAB\eeglab2024.2';
addpath(EEGLAB_Path)
eeglab

% Set Pathway to EEG Functions
EEGFUN_path = append('C:\Users\lledesma\Documents\GitHub\EEG\EEG_Cleaning');
EEGFUN2_path = append('C:\Users\lledesma\Documents\GitHub\EEG\generalfun');
addpath(EEGFUN_path)
addpath(EEGFUN2_path)

%%%%%%%%%%%%%%%%%%%% SET UP PARALLEL PROCESSING %%%%%%%%%%%%%%%%
% Obtain the number of available cores
numCores = feature('numcores');
disp(['Number of available cores: ', num2str(numCores)]);

% Start the recruting these cores
parpool(numCores); 


%%%%%%%%%%%%%%%%%%%%%%%% Clean the rsEEG data %%%%%%%%%%%%%%%%%%%%%%%

% Inset the needed parameters
EEG_dir = 'C:\Users\lledesma\Documents\MegaGrant\03_Eyes_Open_Eyes_Closed_Separated\';
EEG_dir_info = dir(EEG_dir);
EEG_filenames = {EEG_dir_info(contains({EEG_dir_info.name}, ".set")).name};
EEG_fullpath = append(EEG_dir, EEG_filenames);
EEG_save_path = 'C:\Users\lledesma\Documents\MegaGrant\04_Clean_EEG_Data\';
EEG_csv_save_path = 'C:\Users\lledesma\Documents\MegaGrant\04_Clean_EEG_QS_CSV\';
EEG_excel_save_path = 'C:\Users\lledesma\Documents\MegaGrant\';
chan_loc = 'C:\\Users\\lledesma\\Documents\\MATLAB\\eeglab2024.2\\plugins\\dipfit\\standard_BEM\\elec\\standard_1005.elc';
input_ex = '_RAW.set';
output_ex = '_RAW_cleaned.set';

% Run the rsEEG cleaning code
clean_wet_rseeg(EEG_fullpath, '.set', EEG_save_path, EEG_csv_save_path, ...
    EEG_excel_save_path, 'No', chan_loc, 62, 500, 70, input_ex, output_ex )

%%%%%%%%%%%%%%%%%%%%%%%%% Running FFT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Insert more pathways
inputdir = 'C:\Users\lledesma\Documents\MegaGrant\04_Clean_EEG_Data\';  
outputdir = 'C:\Users\lledesma\Documents\MegaGrant\05_FFT_Welch_Outcomes\';
bands = {'delta', 'theta', 'alpha', 'beta'};  
frexvc = [1, 4; 4, 8; 8, 13; 13, 30];  % [start, end] Hz for each band
setfiles = dir(fullfile(inputdir, '*.set'));  
filenames = {setfiles.name};  
outputname = "_struct_fftx2.mat";

% Extract absolute, relative and power spectral density with fftx2 output for all files
extract_eeg_freqband_power_fftx(bands, frexvc, inputdir, filenames, outputdir, outputname);

%%%%%%%%%%%%%%%%%%%%%%% Running Welch %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% FBpowelchx parameters 
winsec = 2;
nOverlap_per = 50;
outputname = "_struct_welchx2.mat";

% Run FPpowelchx - will create structs with welchx2 output for all files
extract_eeg_freqband_power_welchx(bands, frexvc, inputdir, filenames, winsec, nOverlap_per, outputdir, outputname)

%%%%%%%%%%%%%%%%% Loading FFT and Welch Structs %%%%%%%%%%%%%%%%%%%%%%

% Create structure names
strctfieldnames = {'hz', 'powavg', 'chanlabl',... 
                   'deltaFB', 'thetaFB', 'alphaFB', 'betaFB', ...
                   'absdelta', 'abstheta', 'absalpha', 'absbeta',...
                   'avgdelta', 'avgtheta', 'avgalpha', 'avgbeta',...
                   'reldelta', 'reltheta', 'relalpha', 'relbeta'};

% Specify the directory containing the fftx2 .mat files
matfiles = dir(fullfile(outputdir, '*fftx2.mat'));

% Load in saved .mat files
afftx = loadStructs(outputdir, matfiles, strctfieldnames);

% Specify the directory containing the welchx2 .mat files
matfiles = dir(fullfile(outputdir, '*welchx2.mat'));

% Load in saved .mat files
awelchx = loadStructs(outputdir, matfiles, strctfieldnames);


%%%%%% Creating topography x frequency band output table (Wide) %%%%%%

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

% Set pathways to save the topography FB output
topoFBAvgPowFFT = 'C:\Users\lledesma\Documents\MegaGrant\06_Final_FFT_Welch_CSVs\topographyFBAvgPowFFT.csv';
topoFBAvgPowWelch = 'C:\Users\lledesma\Documents\MegaGrant\06_Final_FFT_Welch_CSVs\topographyFBAvgPowWelch.csv';

% Obtain a table with avg power for frequency bands and topography
topographyFBAvgPowFFT = topoFBpow(afftx, nbchanstruct, FB_spectral_properties);
topographyFBAvgPowWelch = topoFBpow(awelchx, nbchanstruct, FB_spectral_properties);

% Save the FFT and Welch Output
writetable(topographyFBAvgPowFFT, topoFBAvgPowFFT);
writetable(topographyFBAvgPowWelch, topoFBAvgPowWelch);
