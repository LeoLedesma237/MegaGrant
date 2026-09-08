% Load these dryEEG parameters
preprocParams = struct();

% === File Naming ===
preprocParams.fileExtRaw = '.set'; % Extension of raw file
preprocParams.fileExtEeg = '_cleaned_wet.set'; % Suffix for processed EEG file
preprocParams.fileExtQc = strrep(preprocParams.fileExtEeg, '.set', '_QC.csv'); 

% === Channel Removal === 
preprocParams.chanRmv = {'Aux1','Aux2','VEOG','HEOG'};

% === Channel Locations ===
preprocParams.chanLoc = 'C:\\Users\\lledesma\\Documents\\MATLAB\\eeglab2024.2\\plugins\\dipfit\\standard_BEM\\elec\\standard_1005.elc';

% === Channel Detrending ===
preprocParams.detrend = 'no'; % 'yes' is recommended 

% === Filtering ===
preprocParams.filtLow = 0.5;
preprocParams.filtHigh = 30;

% === Notch Filter (US = 50 Hz) ===
preprocParams.NotchfiltLow = 49;
preprocParams.NotchfiltHigh = 50;

% === Bad Channel Detection ===
preprocParams.badChFlatLineCrit = 5;
preprocParams.badChChannCrit = 0.8;
preprocParams.badChLineNoise = 4;

% === Re-referencing ===
preprocParams.reRefchan = []; % WholeHead

% === Downsampling ===
preprocParams.downrate = 250; % High sampling rate results in good ICA (rec = 500)

% === ICA ===
preprocParams.ICAext = 1;
preprocParams.ICAlrate = 5e-5; % Highly recommended
preprocParams.ICAsteps = 2000; % Same here too 
preprocParams.ICAstopTol = 1e-7;

% === IC Label ===
preprocParams.ICL.thresh = struct('brain', 0.7,... % Not artifact (obviously)
                                  'muscle', 0.7, ...
                                  'eye', 0.7, ...
                                  'heart', 0.8, ...
                                  'line', 0.8, ...
                                  'chan', 0.8, ...
                                  'other', 0.8);

% === Bad Segments Identifcation ===
preprocParams.badSegOverlp = 50; % in percentage
preprocParams.badSegthresh = 100; % Amplitude
preprocParams.badSegsec = 2; % Segment length in seconds


