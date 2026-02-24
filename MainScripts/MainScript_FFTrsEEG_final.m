% This script will be loading clean (preprocessed) rsEEG files and running
% fast Fourier transform (FFT) on them. We will be doing this using
% FieldTrip functions. For our analysis, we are only interested in
% frequencies between 0.5-35 Hz, so that will be our frequencies of interest
% (foi). We chose this range to match that of the following article:
% 'Brain Maturation in Adolescence: ConcurrentChanges in Neuroanatomy and 
% Neurophysiology' by Whitford et al., (2007). The recordings are already 
% segmented into 4 second trials, thus each one will be converted into the 
% frequency domain and then average to produce one average power spectra.
% They are 4 second trials because that is what Whitford's paper did-
% additionally this will likely produce more reliable power estimates for
% lower frequencies (0.5-4 Hz). To be optimal, we will use the max frequency
% resolution (1/recording length in seconds) as a fixed step for power values
% between our foi range. To examine the power spectra for individual trials, 
% we can include "cfg.keeptrials = 'yes'" into into the configuration structure. 
%
% Calculating Power Spectra:
%   Each preprocessed rsEEG recording will go through FFT on using the Field Trip 
%   approach with a Hanning Window Taper. This is the recommended approach for 
%   rsEEG analysis at beta frequencies or less
%   (https://www.fieldtriptoolbox.org/workshop/nigeria2025/frequency/)
%
% Data Output:
%   A .csv file with three variables: channel, frequency, power (long
%   format).
%
% NOTE
%   We decided to run FFT on preprocessed rsEEG files that were initially
%   cleaned locally but afterwards saved on the server. This was done for
%   storage reasons and the process should overall still be quick even with
%   potential bottlenecking. 

% Clear all information from Workspace and Command Window
clc; clear;

% Add paths to custom funtions and start Field Trip
addpath 'C:\Users\lledesma\Documents\MATLAB\fieldtrip-20250928';

% Set up pathways to the processed data (.mat files - on the server)
%eegProcessed_pathway = 'Y:\MODIFIED_DS\EEG\rsEEG\02_Processed';
eegProcessed_pathway = 'C:\Users\lledesma\Documents\MegaGrant\Data\MODIFIED_DS\rsEEG\02_Processed';

% Set up pathway to store a CSV with all FFT information
fftPathway = 'C:\Users\lledesma\Documents\MegaGrant\Data\FINAL_DS\rsEEG\FFT';

% Set up pathway to store a CSV with all preprocessed information (.summary info)
CSV_pathway = 'C:\Users\lledesma\Documents\MegaGrant\Data\REPORTS\EEG';

% Set up an errors pathway
HTML_pathway   = fullfile(CSV_pathway, "html");   % Just keep this in for now
ERRORS_pathway = fullfile(HTML_pathway, "errors");

%Frequencies of interest (foi)
lowfreq = 0.5;
highfreq = 35;

% processed, fft and error files
procc_ext = '_preproc.mat';
fft_ext = '_fft.csv';
error_fft_ext_csv = strrep(fft_ext, '.csv', '_failed.csv');

%%%%%%%%%%%%%%%%%%%%                        %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%                        %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%      REST OF THE CODE IS AUTOMATIC      %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%                        %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%                        %%%%%%%%%%%%%%%%%%%%

% Load in FieldTrip functions
ft_defaults;

% Create directories if they already don't exist (for outputs)
mkdir(eegProcessed_pathway);
mkdir(fftPathway);

% Load in file names of processed rsEEG files
cfg = [];
cfg.inputdir1      = eegProcessed_pathway;
cfg.outputdir      = fftPathway;
cfg.inputpattern1  = ['*', procc_ext];
cfg.inputpattern2  = ['*', procc_ext]; 
cfg.outputpattern  = ['*', fft_ext];
cfg.fullname       = 'yes'; % Returns the pathway (makes easier to load data)

% Return files that have and have not been processed
[pendingRawNames, processedRawNames] = ft_notyetprocessed(cfg);

% Set up the configuration for parallel processing
delete(gcp('nocreate'));        % Kills any old pool (12 workers or whatever)                                      
myCluster = parcluster('local');
delete(myCluster.Jobs);         % Clears old crash files
myCluster.NumWorkers = 8;       % I think this should more than suffice
parpool(myCluster);             % Starts the cluster with specified number of workers
fprintf('Successfully started clean pool with %d workers\n', myCluster.NumWorkers);

% Start the parfor loop
parfor iter = 1:length(pendingRawNames)
    try
        % Prepare names for files to be loaded and saved
        one_preproc_full = pendingRawNames{iter}; 
        [~, name, ext] = fileparts(one_preproc_full);
        one_preprocc = [name ext]; % regular name
        one_partfft = [name fft_ext];
        error_csv = fullfile(ERRORS_pathway, [name error_fft_ext_csv]);

        % Delete the error csv file if it already exists
        if isfile(error_csv); delete(error_csv); end 
        stage = 'File was unable to be loaded in';
        
        % Load in the file name
        dat = load(one_preproc_full);
        stage = 'File was loaded in successfully';
        
        % Set up some parameters
        fs = dat.fsample;
        N = size(dat.trial{1}, 2);
        len = N/fs; % 4-second time windows
        freq_res = 1/len;
        
        % Create a configuration to get the power spectra 
        cfg = [];
        cfg.output  = 'pow';
        cfg.channel = 'all';
        cfg.method  = 'mtmfft';
        cfg.taper   = 'hann';
        cfg.foi     = lowfreq:freq_res:highfreq; 
        base_freq1  = ft_freqanalysis(cfg, dat);
        stage = 'FFT was ran successfully';
        
        % Assuming base_freq1 is your frequency structure for the current recording
        pow = base_freq1.powspctrm;      % channels x frequencies matrix
        channels = base_freq1.label;      % cell array of channel names (Nchan x 1)
        freqs = base_freq1.freq;          % 1 x Nfreq or Nfreq x 1 vector
        
        % Vectorize everything correctly
        n_chan = numel(channels);
        n_freq = numel(freqs);
        
        % Repeat channel names: each channel appears once per frequency
        channel_col = repmat(channels, n_freq, 1);                
        frequency_col = repelem(freqs(:), n_chan, 1);             
        power_col = pow(:);    
        
        % Create the table
        long_table = table(...
            channel_col, ...
            frequency_col, ...
            power_col, ...
            'VariableNames', {'channel', 'frequency', 'power'});
        
        % Optional: sort by channel then frequency for cleaner CSV (optional but nice)
        long_table = sortrows(long_table, {'channel', 'frequency'});
        stage = 'FFT table was created sucessfully';
        
        % Save the FFT Output
        full_name = fullfile(fftPathway, one_partfft);       
        writetable(long_table, full_name);

    catch ME
        fprintf('Iteration %d crashed: %s\n', iter, ME.message);
        % Optional: rethrow if you want the whole parfor to stop
        %rethrow(ME);
        
        fid = fopen(error_csv, 'a');
        msg = strrep(ME.message, '"', '""');
        fprintf(fid, '%d,"%s","%s"\n', iter, stage, msg);
        fclose(fid);

    end

end
