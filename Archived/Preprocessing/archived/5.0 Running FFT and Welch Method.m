% Description: This script loads in cleaned .set files and runs
% FFT and Welch's Method on them. The final output are two CSV files
% that contain the average power for all frequency bands of interest
% in all topographical locations of interest. These data are saved
% in wide format.


% Set pathway to general functions
EEGFUN_Path = 'C:\Users\lledesma\Documents\GitHub\EEG\generalfun';
addpath(EEGFUN_Path)

% Run EEGLAB
EEGLAB_Path = 'C:\Users\lledesma\Documents\MATLAB\eeglab2024.2'
addpath(EEGLAB_Path)
eeglab

% Insert more pathways
inputdir = 'C:\Users\lledesma\Documents\MegaGrant\04_Clean_EEG_Data\';  
outputdir = 'C:\Users\lledesma\Documents\MegaGrant\05_FFT_Welch_Outcomes\';
topoFBAvgPowFFT = 'C:\Users\lledesma\Documents\MegaGrant\06_Final_FFT_Welch_CSVs\topographyFBAvgPowFFT.csv';
topoFBAvgPowWelch = 'C:\Users\lledesma\Documents\MegaGrant\06_Final_FFT_Welch_CSVs\topographyFBAvgPowWelch.csv';


% %
% % % % % %  Part 1: Running FFT
% %

% FBpowfftx paramters
bands = {'delta', 'theta', 'alpha', 'beta'};  
frexvc = [1, 4; 4, 8; 8, 13; 13, 30];  % [start, end] Hz for each band
setfiles = dir(fullfile(inputdir, '*.set'));  
filenames = {setfiles.name};  
outputname = "_struct_fftx2.mat";

% Run FBpowfftx - will create structs with fftx2 output for all files
FBpowfftx(bands, frexvc, inputdir, filenames, outputdir, outputname);

% %
% % % % % %  Part 2: Running Welch's method
% %

% FBpowelchx parameters 
winsec = 2;
nOverlap_per = 50;
outputname = "_struct_welchx2.mat";

% Run FPpowelchx - will create structs with welchx2 output for all files
FBpowelchx(bands, frexvc, inputdir, filenames, winsec, nOverlap_per, outputdir, outputname)

% %
% % % % % %  Part 3: Loading in fftx2 .mat files
% %

% Create structure names
strctfieldnames = {'hz', 'powavg', 'chanlabl', 'deltaFB', 'thetaFB', 'alphaFB', 'betaFB', ...
                'avgdelta', 'avgtheta', 'avgalpha', 'avgbeta'};

% Specify the directory containing the fftx2 .mat files
matfiles = dir(fullfile(outputdir, '*fftx2.mat'))

% Load in saved .mat files
afftx = loadStructs(outputdir, matfiles, strctfieldnames)

% %
% % % % % %  Part 4: Loading in welchx2 .mat files
% %

% Specify the directory containing the welchx2 .mat files
matfiles = dir(fullfile(outputdir, '*welchx2.mat'));

% Load in saved .mat files
awelchx = loadStructs(outputdir, matfiles, strctfieldnames);

% %
% % % % % %  Part 5: Creating topography x frequency band output table
% (WIDE) for fftx2
% %

% Following Whitford 2007
% Must manually introduce what topography and channels to average by
nbchanstruct = struct();
nbchanstruct.frontal = {'Fp1', 'Fp2', 'F7', 'F3', 'Fz', 'F4', 'F8', 'FC3', 'FCz', 'FC4'};
nbchanstruct.temporal = {'T7', 'TP7', 'T8', 'TP8'};
nbchanstruct.parietal = {'CP3', 'CPz', 'CP4', 'P3', 'Pz', 'P4'};
nbchanstruct.occipital = {'O1', 'Oz', 'O2'};

% Frequency bands that we are interested in
avgFB = {'avgdelta', 'avgtheta', 'avgalpha', 'avgbeta' };

% Obtain a table with avg power for frequency bands and topography
topographyFBAvgPowFFT = topoFBpow(afftx, nbchanstruct, avgFB);

% Save the table
writetable(topographyFBAvgPowFFT, topoFBAvgPowFFT);

% %
% % % % % %  Part 5: Creating topography x frequency band output table
% (WIDE) for welchx2
% %

% Obtain a table with avg power for frequency bands and topography
topographyFBAvgPowWelch = topoFBpow(awelchx, nbchanstruct, avgFB);

% Save the table
writetable(topographyFBAvgPowWelch, topoFBAvgPowWelch);

