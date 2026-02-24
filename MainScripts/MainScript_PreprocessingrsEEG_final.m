% This script will be preprocessing (cleaning) the rsEEG data from the
% MegaGrant project. This will include only eyes closed recordings (we will
% not clean eyes open at all). The goal is to generate a preprocessing
% pipeline that closely emulates the methods of 'Brain Maturation in 
% Adolescence: Concurrent Changes in Neuroanatomy and Neurophysiology' by
% Whitford et al., 2007. To preprocess this data, we
% will be using custom functions along with well known functions from
% FieldTrip. To run this code, you will need:
% a) to have FieldTrip installed
% b) to have Parallel Computing Toolbox installed
% c) to have Signal Processing Toolbox installed
% d) to have NoiseTools Toolbox installed
% e) to have access to Leo's EEG github repository
% f) to have downloaded the ColorBrewer functions (with Leo's EEG github)
%  
% Additionally, for conveniece (on this User's end), absolute pathways were
% used to specify raw and processed data locations. These will have to be
% modified if the code is to be used on a different account/PC.
%
% Preprocessing steps:
% a) Segments of 4 seconds (Whitford)
% 1) Robust detrending (novel)
% 2) Down-sampling to 512 Hz (Whitford)
% 3) Removing bad channels (novel)
% 4) Low-pass filtering (Whitford)
% 5) Rejecting bad trials (novel)
% 6) Rejecting bad trials + Fixing partially bad trials (novel)
% 7) Interpolating removed channels (novel)
% 8) Robust referencing (novel)
% 9) Remove line noise (Russia = 50 Hz; US = 60 Hz) (novel)
%
% Justification for this preprocessing pipeline
%   This pipeline was mostly inspired by a partially finished example
%   present in ‘Robust detrending, referencing, outlier detection, and inpainting 
%   for multichannel data and some FieldTrip guides online. Some of the pipeline 
%   was justified by what naturally seems appropriate. Both of these
%   aspects above have a (novel) placed next to is. Let's quickly explain
%   them in more detail. The robust detrending was designed to basically
%   replaced a high-pass filter. This is because the later removes all
%   signal in that frequency, both above and below the specfied threshold. 
%   This is because the amplitude for that regions is reduced by
%   ~30% and mathematically its power is reduced by ~50%. Additionally
%   nearby frequencies also get attenuated a bit (think of a diagonal
%   line). Anyway high-pass filtering throws out both noise and brain data
%   at, before and slightly after the threshold. Other cleaning steps are
%   just common sense, we identify and interpolate noisy channels and
%   remove trials that are too problematic that are mostly made up of
%   noise. The robust referencing was designed to refernece the EEG to the
%   whole head without spreading noise, which is nice. We don't include ICA
%   because there are no blinks to remove.
% 
%   The preprocessing steps with (Whitford) next to it are directly from
%   the paper. We start with segments of 4 seconds because that is what is
%   used later for FFT, probably to get more reliable estimates for lower
%   frequencies (0.5 Hz). The data were re-sampled in their paper to 512 Hz,
%   and this is a good number due to the rule of power of 2, where FFT
%   is computationally efficient and faster when the sampling rate is one
%   made up by the power of two (Ex: power of two means 2^10 = 512). 
%   In the paper they used a low pass filter of 100 Hz and no high-pass filtering,
%   so we will be doing the same. In the paper they did note remove line
%   noise, we will just because there are cases where having line noise
%   (according to Grok) can cause spectral leakage, meaning our power from
%   upper beta bands can be inflated due to the very high activity at 50
%   Hz.
%
% Not Full Preprocessing Code:
%   This code is starting at an intermediate step. A previous script loaded
%   the rsEEG raw files, which are Brain Vision Recorder (BVR) files, and
%   separated eyes open vs eyes closed condition (they were both saved
%   within the same recording). These files were now .set and .fdt files.
%
% Data Input:
%   Eyes eyes closed .set/.fdt files. These are still raw files, the previous 
%   code only separated the recordings and saved them but did not alter the data
%   at all. Some of the initial recordings failed to have the trigger codes 
%   to differentiate the starting and stopping points of eyes open and eyes
%   closed conditions (both were recorded within the same EEG file). Thus
%   the number of .set recordings we have available will be slightly less
%   than the original .eeg/.vhdr/.vmrk files.
%
% Data Output:
%   - Processed EEG data will be saved as one .mat files that can be read into 
%    matlab using the `load()` function. Initially there were two due to
%    ICA but we will not be using it in this pipeline since there are no
%    blinks.
%   - The .mat file will also contain preprocessing outputs (ex: num of
%   channels deleted, num of trials rejected) and they will be loaded in
%   and then saved as one CSV file to be read into R (or another language).
%   - PNGs are generated from most of the preprocessing functions below,
%   they are temporarlys saved within a PNG folder and then discarded to
%   save up space.
%   - HTML files are generated with all PNG from that par for loop
%   iteration saved within it. This cam allow for visual investigationg of
%   the how the preprocessing went.                                                     
%
% Parallel Processing:
%   This technique allows for multiple EEG recordings to be processed simulatenously
%   by dividing the work using multiple cores. It is a finicky process in which
%   iteration failures will cause the full loop to stop. Thus error
%   handling techniques were incorporated to circumvent this.
%
% Error Handling:
%   There are a few measures of error handling in the code below. The first
%   are the try/catch blocks that will prevent the par for loop from
%   crashing entirely if an iteration failed. The second is that a
%   temporary dataset (temp_data) is saved after each preprocessed step-
%   thus if an iteration fails then the most up to date transformation is
%   saved with a 'failed' in the name. However, we don't care for this
%   feature so it has been disabled (no 'failed' .mat files will be saved).
%   Additionally, error csv files are created for each failed iteration with some 
%   info explaining why the failure occurred. It may not be possible to make all 
%   EEG recordings go through the full pipeline succesfully since there may be cases 
%   where a recording has too many bad trials or channels, which causes crashes with 
%   subsequent functions or the recording itself can be corrupted- having no EEG data
%   saved within it (.fdt files with 0 bytes of data).
%
% Important (local process + storage management):
%   It is highly recommended to save preprocessed EEG files locally. This puts
%   less stress on the server during parallel processing and can mitigate errors
%   related to permissions. Additionally, it is good practice to use some
%   of the available cores (not all) when running parallel processing to
%   mitigate crashes from overwheleming the PC. We should also process not
%   too many files all at once. It is best to copy over part of the raw
%   files, fully process them, get the FFT files and then cut and paste the
%   information to the server, thus freeing up space on the computer. Also
%   to prevent memory problems, we are also restarting parallel processing
%   after x number of recordings have been processed.

% Clear all information from Workspace and Command Window
clc; clear;

% Add paths to custom funtions and start Field Trip
addpath 'C:\Users\lledesma\Documents\MATLAB\fieldtrip-20250928';
addpath 'C:\Users\lledesma\Documents\GitHub\EEG\FieldTripFun';
addpath 'C:\Users\lledesma\Documents\MATLAB\NoiseTools';
addpath(genpath('C:\Users\lledesma\Documents\GitHub\EEG\FieldTripFun'));

% Set up pathways to load the raw data (files copied here manually and then
% probably deleted)
wetRaw_pathway = 'C:\Users\lledesma\Documents\MegaGrant\Data\MODIFIED_DS\rsEEG\01_Eyes_Open_Eyes_Closed_Separated';

% Set up pathways to save processed data (.mat files)
eegProcessed_pathway = 'C:\Users\lledesma\Documents\MegaGrant\Data\MODIFIED_DS\rsEEG\02_Processed';

% Set up pathway to store a CSV with all preprocessed information (.summary info)
CSV_pathway = 'C:\Users\lledesma\Documents\MegaGrant\Data\REPORTS\EEG';

% Set up pathways to save processing reports (.htmls) and PNGs
HTML_pathway   = fullfile(CSV_pathway, "html");   
PNG_pathway    = fullfile(HTML_pathway, "PNGs");
ERRORS_pathway = fullfile(HTML_pathway, "errors");

% Raw, processed, and error file extensions
raw_ext = '.set';

procc_ext = '_preproc.mat';
procc_html = strrep(procc_ext, '.mat', '.html');
error_procc_ext = strrep(procc_ext, '.mat', '_failed.mat');
error_procc_ext_csv = strrep(procc_ext, '.mat', '_failed.csv');


%%%%%%%%%%%%%%%%%%%%                        %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%                        %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%      REST OF THE CODE IS AUTOMATIC      %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%                        %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%                        %%%%%%%%%%%%%%%%%%%%

% Load in FieldTrip functions
ft_defaults;

% Load configuration for plot visualizations
[cfg_view, cfg_time, cfg_fft, cfg_topo, cfg_sum, cfg_stack, cfg_chntrfft] = ft_visualizationcfgs();

% Create configuration for saving PNGs (Will be used later for generating report)
% Specify parameters for saving PNGs 
cfg_saveplots = [];
cfg_saveplots.visibleplots = 'no';
cfg_saveplots.saveplots    = 'yes'; % We will not be saving any plots!
cfg_saveplots.main         = 'no'; % Are they end results summary plots or not
cfg_saveplots.skip         = 8; % Number of starting summary plots
cfg_saveplots.plotfolder   = PNG_pathway; % This gets updated within the for loop

% Modify default configuration to work with our data
cfg_time.layout = [8 8]; % To fit the 62 channels
cfg_fft.layout = [8 8]; 

% Introduce the cfg_saveplots structure within our visualization plot functions
cfg_time.saveplots  = cfg_saveplots;
cfg_fft.saveplots   = cfg_saveplots;
cfg_topo.saveplots  = cfg_saveplots;
cfg_stack.saveplots = cfg_saveplots;
cfg_corchans.saveplots = cfg_saveplots; % This configuration is typically optional
cfg_chntrfft.saveplots = cfg_saveplots;

% Create directories if they already don't exist (for outputs)
mkdir(eegProcessed_pathway);
mkdir(CSV_pathway);
mkdir(HTML_pathway);
mkdir(PNG_pathway);
mkdir(ERRORS_pathway);

% Load in file names (wet & dry) split by pending and already processed
cfg = [];
cfg.inputdir1      = wetRaw_pathway;
cfg.outputdir      = eegProcessed_pathway;
cfg.inputpattern1  = ['*', raw_ext];
cfg.inputpattern2  = ['*', raw_ext]; 
cfg.outputpattern  = ['*', procc_ext];
cfg.fullname       = 'yes'; % Returns the pathway (makes easier to load data)

% Return files that have and have not been processed
[pendingRawNames, processedRawNames] = ft_notyetprocessed(cfg);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Setting Up Patallel Processing Parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
delete(gcp('nocreate'));        % Kills any old pool (12 workers or whatever)                                      
myCluster = parcluster('local');
delete(myCluster.Jobs);         % Clears old crash files
myCluster.NumWorkers = 8;       % More than this will cause par for to fail
parpool(myCluster);             % Starts the cluster with specified number of workers
fprintf('Successfully started clean pool with %d workers\n', myCluster.NumWorkers);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% PART 1 %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Quick fix 
%pendingRawNames = pendingRawNames(1:200);

% Prepare the batches (number of files processed at a time)
N = length(pendingRawNames);
batchSize = 30;
numBatches = ceil(N / batchSize);


% Set up a for loop first that sets up batches for parfor loop
for batch = 1:numBatches
    startIdx = (batch-1)*batchSize + 1;
    endIdx   = min(batch*batchSize, N);
    
    % Extract current batch of indices
    batchIndices = startIdx:endIdx; 

    if mod(batch, 5) == 0
        disp('restarting parallel processing to save up memory')
        pause(5);
        delete(gcp('nocreate'));        % Kills any old pool (12 workers or whatever)                                      
        myCluster = parcluster('local');
        delete(myCluster.Jobs);         % Clears old crash files
        myCluster.NumWorkers = 8;       % More than this will cause par for to fail
        parpool(myCluster);             % Starts the cluster with specified number of workers
        fprintf('Successfully started clean pool with %d workers\n', myCluster.NumWorkers);
    end

   % Run parfor loop 
    parfor iter = batchIndices
        try
            % For each worker to produce the same results each time
            rng(iter);
    
            % Prepare names for files to be loaded and saved
            one_raw_full = pendingRawNames{iter}; 
            [~, name, ext] = fileparts(one_raw_full);
            one_raw = [name ext]; % regular name
            one_partpreproc = [name procc_ext];
            one_parthtml = [name procc_html];
            html_full = fullfile(HTML_pathway, one_parthtml);
            error_mat = fullfile(eegProcessed_pathway, [name error_procc_ext]);
            error_csv = fullfile(ERRORS_pathway, [name error_procc_ext_csv]);
            stage = 'File was unable to be read';
            temp_dat = [];
            
            % Update the pathway to save PNGs and create it (delete if already present)
            % (This code can cause errors if Image opened in R Studio)!
            one_PNG_pathway = fullfile(PNG_pathway, name);
            if exist(one_PNG_pathway, 'dir'); rmdir(one_PNG_pathway, 's'); end
            mkdir(one_PNG_pathway);

            % Same as above delete error file or html file if they already exists
            if isfile(error_mat); delete(error_mat); end 
            if isfile(error_csv); delete(error_csv); end 
            if isfile(html_full); delete(html_full); end 
           
            % Load in the EEG data (full name)
            cfg = [];
            cfg.dataset = one_raw_full; % Point to .vhdr
            cfg.channel = {'all', '-VEOG', '-HEOG', '-Aux1', '-Aux2'};
            cfg.continuous = 'yes';
            data_noisy = ft_preprocessing(cfg);
            stage = 'Reading in .set file was successful';

            % Check to see if file is corrupted (empty data; .fdt is empty)
            EEG_dat = cat(2, data_noisy.trial{:});
            if isempty(EEG_dat)
                stage = 'Corrupted recording, has no EEG data within data.trial - check .fdt file for corruption';
            end
           
            % Segment the EEG data (for plotting purposes)
            cfg = [];
            cfg.length = 2; % seconds
            cfg.overlap = 0; % non-overlapping
            data_noisy_segmented = ft_redefinetrial(cfg, data_noisy);
           
           
            %%%%%%%%%%%%%% BEFORE STARTING THE PROCESSING PIPELINE %%%%%%%%%%%%%%
        
            % Save plotting configuration into new configurations (needed for parallel processing)
            cfg_time2     = cfg_time;
            cfg_fft2      = cfg_fft;
            cfg_topo2     = cfg_topo;
            cfg_sum2      = cfg_sum;
            cfg_stack2    = cfg_stack;
            cfg_corr2     = cfg_corchans;
            cfg_chntrfft2 = cfg_chntrfft;     
       
            % Update each plot configuration to include new save PNG pathway (needed for parallel processing)
            cfg_time2.saveplots.plotfolder = one_PNG_pathway;
            cfg_fft2.saveplots.plotfolder = one_PNG_pathway;
            cfg_topo2.saveplots.plotfolder = one_PNG_pathway;
            cfg_sum2.saveplots.plotfolder = one_PNG_pathway;
            cfg_stack2.saveplots.plotfolder = one_PNG_pathway;
            cfg_corr2.saveplots.plotfolder = one_PNG_pathway;
            cfg_chntrfft2.saveplots.plotfolder = one_PNG_pathway;
        
            % Add electrode positions into the data (10-05 template)
            elec_file = which('standard_1005.elc');
            data_noisy.elec = ft_read_sens(elec_file);
           
            % Define neighbors using the standard 10-05 template
            cfg = [];
            cfg.method = 'distance'; % or 'triangulation'
            cfg.layout = 'EEG1005.lay'; % Your layout file
            neighbours = ft_prepare_neighbours(cfg);
           
            % Generate the configuration structure
            data_noisy = ft_inittracker(data_noisy);
           
            %%% PLOTS: BEFORE DETRENDING %%%                                             
            cfg_stack2.trial = 7; ft_plotstack(cfg_stack2, data_noisy_segmented);  
            cfg_stack2.trial = 'all'; ft_plotstack(cfg_stack2, data_noisy);
        
            %%%%%%%%%%%%%%%%%%% PART 1: ROBUST DETREND THE DATA %%%%%%%%%%%%%%%%%%%%
            
            % Use custom robust detrending function
            cfg = [];
            cfg.robustdetrend.concatenate  = 'yes';
            cfg.robustdetrend.order        = 10;
            cfg.robustdetrend.demean       = 'yes';
            cfg.robustdetrend.log          = 'yes';
             
            % Robust Detrend the EEG data; % data = data_noisy
            data_detrended = ft_robustdetrend(cfg, data_noisy);
            stage = 'Part 1: Robust detrending was successful';
            temp_dat = data_detrended;
            
            % Segment the EEG data for plotting purposes
            cfg = [];
            cfg.length  = 2;        % segment length in seconds
            cfg.overlap = 0;        % 0 for non-overlapping (100% = fully overlapping)
            data_detrended_segmented = ft_redefinetrial(cfg, data_detrended);

            %%% PLOTS: AFTER DETRENDING AND TEMP SEGMENTING %%%
            ft_plotchannelavg(cfg_time2, data_detrended_segmented);
            ft_plotchannelfft(cfg_fft2, data_detrended_segmented);
            cfg_stack2.trial = 'all'; ft_plotstack(cfg_stack2, data_detrended);
            
            %%%%%%%%%%%%%%%%%%%%%% RECORD EEG VARIANCE %%%%%%%%%%%%%%%%%%%%%%%
            
            % Create a configuration structure
            cfg = [];
            cfg.eegvarsum.log = 'yes';
            
            % Add variance information into the data
            data_detrended = ft_eegvarsum(cfg, data_detrended);

            %%%%%%%%%%%%%%%%%%% PART 2: Downsampling Data  %%%%%%%%%%%%%%%%%%%

            % Create a structure to downsample the EEG data
            cfg_down = [];
            cfg_down.resamplefs = 512;          % New target sampling rate (Power of 2)
            cfg_down.detrend    = 'no';         % Usually fine to leave as 'no' if you'll filter later
            cfg_down.method     = 'resample';   % Default polyphase resampling (good quality, anti-alias filtered)
            
            % Downsample the data
            data_down = ft_resampledata(cfg_down, data_detrended);
            stage = 'Part 2: Downsampling EEG data was successful';
            temp_dat = data_down;

            % Update the sampleinfo since it gets deleted above
            data_down.sampleinfo = [1 size(data_down.trial{:},2)];

            %%%%%%%%%%%%%% PART 3: LOW-PASS FILTERING THE DATA %%%%%%%%%%%%%%%
            
            % Create a structure to high-pass filter the data (rmv low frq)
            cfg = [];
            cfg.lowpassfilt.lpfilter = 'yes'; % enable low-pass
            cfg.lowpassfilt.lpfreq = 100; % cutoff frequency in Hz (as in the paper)
            cfg.lowpassfilt.lpfiltord = 4; % same order as high-pass for consistency
            cfg.lowpassfilt.lpfilttype = 'but'; % Butterworth
            cfg.lowpassfilt.lpfiltdir  = 'twopass';  % zero-phase filtering
            cfg.lowpassfilt.log = 'yes';

            cfg.highpassfilt.fullrecordingplots = 'yes';
        
            cfg.saveplots = cfg_saveplots; 
            cfg.saveplots.plotfolder = one_PNG_pathway;
        
            % Low-pass filter the EEG
            data_filt = ft_lowpassfilter(cfg, data_down);
            stage = 'Part 3: Low-Pass Filtering was successful';
            temp_dat = data_filt;
            
            %%%%%%%%%%%%% PART 4: IDENTIFY AND REMOVE BAD CHANNELS %%%%%%%%%%%%%%
            
            % Create a structure to identify and remove bad channels
            cfg = [];
            cfg.removebadchann.concatenate = 'yes'; % combines all trials into one
            cfg.removebadchann.mthresh1 = 5; % 5x larger than median chan var to be an electrode pop
            cfg.removebadchann.mthresh2 = 0.10; % less than 10% of the median chan var to be flat
            cfg.removebadchann.zthresh  = 5; % 5 robust SD higher freq than other channels 
            cfg.removebadchann.highfrqbp  = [30 100]; % high freq range
            cfg.removebadchann.rmvchanplot = 'yes'; 
            cfg.removebadchann.log = 'yes';
            cfg.removebadchann.intpmatrixupdt = 'yes'; % Creates intpmatrix
            cfg.removebadchann.intpmatrixsec = 4; % The intpmatrix will have 4 second segments

            % Drops detected bad trials from channel variance calculation
            cfg.removebadchann.muscleprotection = 'yes';
            cfg.removebadchann.highfrqbp  = [30 100]; % high freq range
        
            % Attenuates peaks before channel variance calculation
            cfg.removebadchann.peakprotection = 'no';
        
            cfg.saveplots = cfg_saveplots; 
            cfg.saveplots.plotfolder = one_PNG_pathway;
            
            % Remove the bad channels
            [data_rmvchan, bad_chans] = ft_removebadchann(cfg, data_filt);
            stage = 'Part 4: Removing bad channels was successful';
            temp_dat = data_rmvchan;
        
            %%%%%%%% PART 5: REMOVE VERY CONTAMINATED TRIALS %%%%%%%%%%
            
            % Create a structure to delete bad segments
            cfg = [];
            cfg.rejectbadseg.seglength   = 4 ; % Segment length in seconds (4 seconds)
            cfg.rejectbadseg.mthresh     = 4 ; % 4 x larger than median to be an artifact
            cfg.rejectbadseg.highfrqbp   = [30 100]; % High frq bands 
            cfg.rejectbadseg.zthresh     = 5;  % robust z score threshold for high frq pwr to detect bad trials
            
            % Specify saving trials if var is due to a few bad channels
            cfg.rejectbadseg.savetrials  = 'yes'; % Saves high var trials if due to small # of channels
            cfg.rejectbadseg.chanprop    = 0.10; % Number of channels to inspect how they contribute to trial var
            cfg.rejectbadseg.zchanpropvar = 5; % Threshold for how much chanprop can contribute to trial var

            % Indicate whether we want to see plots of deleted trials
            cfg.rejectbadseg.badsegplot     = 'yes'; % Create a plot of deleted segments
            cfg.rejectbadseg.indvbadsegplot = 'yes'; % Print out individual trials (rejected)
            cfg.rejectbadseg.onegoodplot    = 'yes'; % Produces a good plot for comparison
    
            cfg.rejectbadseg.log = 'yes';
            cfg.rejectbadseg.intpmatrixupdt = 'yes'; % Updates intpmatrix
        
            % Do not specify peak protection
            cfg.rejectbadseg.peakprotection = 'no';
        
            cfg.saveplots = cfg_saveplots; 
            cfg.saveplots.plotfolder = one_PNG_pathway;
            
            % Remove bad trials
            data_rejseg = ft_rejectbadsegments(cfg, data_rmvchan);
            stage = 'Part 5: Removing bad trials was successful';
            temp_dat = data_rejseg;
    
            %%%%%%%% PART 6: INTERPOLATE CHANNELS IN NOISY SEGMENTS %%%%%%%%%%  
            
            % QC: These trials have electrode pops within them
            %cfg= [];
            %cfg.time = [77, 164];
            %ft_findtrials(cfg, data_rejseg)
            
            % Create a structure to interpolate noisy channels within segments
            cfg = [];
            cfg.chansegmentrepair.zthresh1 = 5; % Robust z-score threshold (general)
            cfg.chansegmentrepair.zthresh2 = 5; % Robust z-score threshold (band-pass)
            cfg.chansegmentrepair.regfrqbp = [30 100]; % Band-Pass filtering high Frequency 
            cfg.chansegmentrepair.type = 'all'; % Use all channel x trials for calculating robust z-score 
            cfg.chansegmentrepair.intmatrixplot = 'yes';
            cfg.chansegmentrepair.afterintplot = 'yes';
            cfg.chansegmentrepair.messages = 'off';
            cfg.chansegmentrepair.log = 'yes';
            cfg.chansegmentrepair.intpmatrixupdt = 'yes'; % Updates intpmatrix

            % Include information from neighbouring channels
            cfg.chansegmentrepair.neighbours = neighbours;

            % Specifiy we want to delete trials with too many bad channels
            cfg.chansegmentrepair.rmvtrials   = 'yes';
            cfg.chansegmentrepair.badchanprop =  0.20;
            cfg.chansegmentrepair.indvbadsegplot =  'yes';

            % Include peak protection just in case
            cfg.chansegmentrepair.peakprotection = 'no';
    
            cfg.saveplots = cfg_saveplots; 
            cfg.saveplots.plotfolder = one_PNG_pathway;
            
            % Interpolate noisy segments 
            data_segfixed = ft_chansegmentrepair(cfg, data_rejseg);
            stage = 'Part 6: Interpolating channels in bad trials was successful. If failed after this it is likely due to many channels deleted in the recording';
            temp_dat = data_segfixed;
    
            %%%%%%%%%%%%%% PART 7: INTERPOLATE REMOVED CHANNELS %%%%%%%%%%%%%%
            
            % Interpolate bad channels using `ft_channelrepair()`
            cfg = [];
            cfg.chaninterp.badchannel     = bad_chans; % from `ft_removebadchann()`
            cfg.chaninterp.method         = 'weighted';
            cfg.chaninterp.neighbours     = neighbours;
            cfg.chaninterp.orig_labels    = data_noisy.label;
            cfg.chaninterp.elec_file      = which('standard_1005.elc');
            cfg.chaninterp.intpchanplot   = 'yes';
            cfg.chaninterp.log            = 'yes';  
    
            cfg.saveplots = cfg_saveplots; 
            cfg.saveplots.plotfolder = one_PNG_pathway;
    
            % Interpolate the channels
            data_intchanns = ft_channelinterpolate(cfg, data_segfixed);
            stage = 'Part 7: Interpolating channels globally was sucessful';
            temp_dat = data_intchanns;
    
            %%%%%%%%%%%%%%%%%%% PART 8: ROBUST RE-REFERENCING %%%%%%%%%%%%%%%%%%
            
            % Create a structure to do robust referencing
            cfg = [];
            cfg.robustreference.thresh =  5; % 4 SD noise from the mean for sample to be weighted 0
            cfg.robustreference.heatmap = 'yes'; % Creates z-score heat map to show amplitude noise 
            cfg.robustreference.padding = 100;  % Converts 100 samples left/right of 0 to 0 
            cfg.robustreference.channelplot = 'yes';
            cfg.robustreference.log = 'yes';
    
            cfg.saveplots = cfg_saveplots; 
            cfg.saveplots.plotfolder = one_PNG_pathway;
            
            % Run robust referencing
            [data_referenced, mn1] = ft_robustreference(cfg, data_intchanns);
            stage = 'Part 8: Robust rereferencing was sucessful';
            temp_dat = data_referenced;

            %%%%%%%%%%%%% PART 9: REMOVE LINE NOISE %%%%%%%%%%%%%%%%
            % We wrote code that is fast and not as good as others but worth
            % it- better approaches will cause MATLAB to be extremly slow and
            % crash!
    
            % Create a strucuture to remove line noise
            cfg = [];
            cfg.rmvlinenoise.dftfilter = 'yes';
            cfg.rmvlinenoise.dftfreq = [50 100 150]; % Russia Line Noise (Hz)
            cfg.rmvlinenoise.dftreplace = 'zero'; % Makes a wider band
            cfg.rmvlinenoise.dftbandwidth = 1; % Keep at 1; making it larger causes problems
            cfg.rmvlinenoise.log = 'yes';

            % Introduce optional more broad line noise removal
            cfg.rmvlinenoise.bsfilter   = 'yes';
            cfg.rmvlinenoise.bsfreq     = [49 51]; % or [59 61] 
            cfg.rmvlinenoise.bsfiltord  = 4; % Butterworth 4th order

            % Generate the plot
            cfg.rmvlinenoise.rmvlineplot = 'yes';
    
            cfg.saveplots = cfg_saveplots; 
            cfg.saveplots.plotfolder = one_PNG_pathway;
            
            % Remove line noise (USA)
            data_rmvlinenoise = ft_removelinenoise(cfg, data_referenced);
            stage = 'Part 9: Removing Line Noise was sucessful';
            temp_dat = data_rmvlinenoise;

            % Save as data clean- the cleaning stops here
            data_clean = data_rmvlinenoise
  

            %%%%%%%%%%%%%%%%%%%%%% RECORD EEG VARIANCE %%%%%%%%%%%%%%%%%%%%%%%
            
            % Create a configuration structure
            cfg = [];
            cfg.eegvarsum.log = 'yes';
            
            % Add variance information into the data
            data_clean = ft_eegvarsum(cfg, data_clean);
            temp_dat = data_clean;
            

            %%%%%%%%%%%%%%% ADD INTPMATRIX INFO INTO SUMMARY %%%%%%%%%%%%%%%%
           
            % Extract the channel labels as a string array
            chanLabels = string(data_clean.cfg.preproc.labels);  

            % Calculate the proportion of trials interpolated for each channel
            intpmatrix = data_clean.cfg.preproc.intpmatrix;
            channel_intp_prop = round(mean(intpmatrix, 2), 3);
            propValues = channel_intp_prop(:); 
            assert(length(chanLabels) == length(propValues), 'Number of channels and values must match!');
            
            % Add the new fields to the existing structure
            for i = 1:length(chanLabels)
                fieldName = append('int_', chanLabels(i));    
                data_clean.cfg.preproc.summary.(fieldName) = propValues(i);
            end

            % Add total interpolation measure
            data_clean.cfg.preproc.summary.int_total = round(mean(intpmatrix(:)), 3);
            data_clean.cfg.preproc.summary.endTrialnum = size(intpmatrix,2);
            temp_dat = data_clean

            %%%%%%%%%%%%% SAVE THE FULLY PROCESSED DATA %%%%%%%%%%%%%%
            
            % Save the 'data' object as a .mat file
            full_name = fullfile(eegProcessed_pathway, one_partpreproc);     
            save(full_name, "-fromstruct", data_clean);

            %%%%%%%%%%%%%%  SUMMARY STATISTICS OF OUR DATA %%%%%%%%%%%%%%
    
            % Remove the skip to save these as summary plots
            cfg_time2.saveplots.skip = 0;
            cfg_fft2.saveplots.skip = 0;
            cfg_topo2.saveplots.skip = 0;
            cfg_sum2.saveplots.skip = 0;
            cfg_stack2.saveplots.skip = 0;
            cfg_corr2.saveplots.skip = 0;
            cfg_chntrfft2.saveplots.skip = 0;
    
            % Assert that these are main plots
            cfg_time2.saveplots.main = 'yes';
            cfg_fft2.saveplots.main = 'yes';
            cfg_topo2.saveplots.main = 'yes';
            cfg_sum2.saveplots.main = 'yes';
            cfg_stack2.saveplots.main = 'yes';
            cfg_corr2.saveplots.main = 'yes';
            cfg_chntrfft2.saveplots.main = 'yes';
    
            % All our custom plots
            data_clean = ft_plotchannelavg(cfg_time2, data_clean);
            data_clean = ft_plotchannelfft(cfg_fft2, data_clean);
            
            % Create the topography comprehensive plot
            [topo_dat, data_clean] = ft_plottopoprep(data_clean);
            ft_plottopo(cfg_topo2, topo_dat);
            
            % Plot all the channels stacked together
            ft_plotstack(cfg_stack2, data_clean);
            
            % Plot the correlations
            ft_corchans(cfg_corr2, data_clean);
            
            % Plot the power spectra of the cleaned data
            ft_plotchantrialfft(cfg_chntrfft2, data_clean)


            %%%%%%%%%%%%%%%%%%%% SAVE AN HTML FILE %%%%%%%%%%%%%%%%%%%%%%
            % Create a structure to save an .html file of all the PNGs
            cfg_html = [];
            cfg_html.inputdir = one_PNG_pathway;
            cfg_html.outputdir = HTML_pathway;
            cfg_html.filename = one_parthtml;
            cfg_html.title = name;
            cfg_html.columns = 2;
            cfg_html.imgwidth = '100%';
            cfg_html.cleanup = 'yes'; 
            
            % Create a .html file of all the PNGs
            ft_png2html(cfg_html)

            
      catch ME
            fprintf('Iteration %d crashed: %s\n', iter, ME.message);
            % Optional: rethrow if you want the whole parfor to stop
            %rethrow(ME);

            fid = fopen(error_csv, 'a');
            msg = strrep(ME.message, '"', '""');
            fprintf(fid, '%d,"%s","%s"\n', iter, stage, msg);
            fclose(fid);

            % Save the 'temp_dat' object as a .mat file
            %if ~isempty(temp_dat)
            %    full_name = fullfile(eegProcessed_pathway, one_partpreproc);     
            %    save(error_mat, "-fromstruct", temp_dat);
            %end
            
        end
    
    end

    fprintf('Finished batch %d/%d (files %d to %d)\n', batch, numBatches, startIdx, endIdx);
    
end


%%%%%%%%%%% LOAD A FEW DATA SAVE VAR NAMES %%%%%%%%%%%%%%%

% .mat file directory
file_path = eegProcessed_pathway;

% Load in file names
all_files_dir = dir(fullfile(file_path, '*preproc.mat'));
all_files = {all_files_dir.name};

% Load in file names that failed (both beforeICA and preproc)
%all_failed_files_dir = dir(fullfile(file_path, '*failed.mat'));
%all_failed_files = {all_failed_files_dir.name};

% Combine all files into one vector
%all_files = [all_files all_failed_files];

% Keep only the first 5 (prevent this chunk taking too long)
few_files = all_files(1:5);

% Load in the .mat file variable names
few_columns = cell(numel(few_files),1);   % pre-allocate for parfor


parfor i = 1:numel(few_files)
    cols = {};
    try
        % Add full file pathway
        full_file = fullfile(file_path, few_files{i});

        % Load in the .mat file
        loaded = load(full_file);

        % If .summary field is present, extract var names
        if isfield(loaded.cfg.preproc, 'summary')
            cols = fieldnames(loaded.cfg.preproc.summary);
        end
    catch
        % skip bad files
    end
    % Save var names within a cell array
    few_columns{i} = cols;
end


% Create a cell array of all variable names present in the data
all_columns = unique(vertcat(few_columns{:}));



%%%%%%%%%%% PART 12: BUILD A QC SUMMARY TABLE %%%%%%%%%%%%%%%

nFiles = length(all_files);
summary_rows = cell(nFiles,1); % pre-allocate for parfor

parfor ii = 1:nFiles
    % keep subject strng from file name
    current_file = all_files{ii};
    subject = strrep(current_file, procc_ext, '');
   
    % Create a table will all var names- each cell is NaN
    row_data = repmat({NaN}, 1, length(all_columns));
    row_table = cell2table(row_data, 'VariableNames', all_columns);
    % Add subject information into the table
    row_table.subject = {subject};
   
    % Try to fill real values
    try
        % Add pathway to the files
        full_file = fullfile(file_path, current_file);
        % load in the .mat file (only cfg to save RAM)
        loaded = load(full_file, 'cfg');
        % Extract the .summary information
        summary = loaded.cfg.preproc.summary;
        % Extract the field names
        summary_fieldnames = fieldnames(summary)'; % cell array
        
        % Create a for loop and insert each cell in the summary table
        for k = 1:length(summary_fieldnames)          
            name = summary_fieldnames{k};               
            value = summary.(name);
           
            % Cell handeling
            if iscell(value)
                row_table.(name) = {strjoin(value, ',')};
            % Integer handeling
            elseif isnumeric(value) && numel(value) > 1
                row_table.(name) = {mat2str(value)};
            % Other
            else
                row_table.(name) = {value};
            end
        end
    catch
        % keep NaN if failed
    end
    
    summary_rows{ii} = row_table;
end

% Expand the row of the summary table each iteration → done after parfor
summary_table = vertcat(summary_rows{:});

% Print the summary table
summary_table

% Save table
T_filename = 'EEG_Preprocessing_Summary_Statistics_EC.csv';
T_full_name = fullfile(CSV_pathway, T_filename);
writetable(summary_table, T_full_name)


