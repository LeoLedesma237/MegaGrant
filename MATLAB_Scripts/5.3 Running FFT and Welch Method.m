% Set pathway to general functions
EEGFUN_Path = 'C:\Users\lledesma.TIMES\Documents\GitHub\EEG\generalfun';
addpath(EEGFUN_Path)

% Obtain the .set file names
inputdir = 'Y:\STUDY 1\All EEG Files Organized\Preprocessed_RAW\RAW_eyes_open_and_eyes_closed_cleaned\';  
setfiles = dir(fullfile(inputdir, '*.set'));  
filenames = {setfiles.name};  

% Set directory to save files/structs
outputdir = 'Y:\STUDY 1\All EEG Files Organized\Preprocessed_RAW\CSV_eyes open and eyes closed FFT\';
outputname = "_struct_fftx2.mat";

% Set up the frequency bands of interest and their Hz range
bands = {'delta', 'theta', 'alpha', 'beta'};  
frexvc = [1, 4; 4, 8; 8, 13; 13, 30];  % [start, end] Hz for each band

% Run FBpowfftx - will create structs with fftx2 output for all files
FBpowfftx(bands, frexvc, filenames, inputdir, outputdir, outputname);

% set up a couple parameters
winsec = 2;
nOverlap_per = 50;
outputname = "_struct_welchx2.mat";

% Run FPpowelchx - will create structs with welchx2 output for all files
FBpowelchx(bands, frexvc, winsec, nOverlap_per, filenames, inputdir, outputdir, outputname)