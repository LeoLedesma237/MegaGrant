% Load these dryEEG parameters
preprocParams = struct();

% === File Naming ===
preprocParams.fileExt.raw = '.set'; % Extension of raw file
preprocParams.fileExt.eeg = '_cleaned_wet.set'; % Suffix for processed EEG file
preprocParams.fileExt.qc = '_QC_wet.csv';        % Suffix for QC report

% === Channel Removal === 
preprocParams.chanRmv = {'Aux1','Aux2','VEOG','HEOG'};

% === Channel Locations ===
preprocParams.chanLoc = 'C:\\Users\\lledesma\\Documents\\MATLAB\\eeglab2024.2\\plugins\\dipfit\\standard_BEM\\elec\\standard_1005.elc';

% === Filtering ===
preprocParams.filt.low = 0.5;
preprocParams.filt.high = 100;

% === Bad Channel Detection ===
preprocParams.badCh.FlatLineCrit = 5;
preprocParams.badCh.ChannCrit = 0.8;
preprocParams.badCh.LineNoise = 4;

% === Re-referencing ===
preprocParams.reRef.chan = []; % WholeHead

% === Downsampling ===
preprocParams.down.rate = 250; % High sampling rate results in good ICA (rec = 500)

% === ICA ===
preprocParams.ICA.ext = 1;
preprocParams.ICA.lrate = 5e-5; % Highly recommended
preprocParams.ICA.steps = 2000; % Same here too 
preprocParams.ICA.stopTol = 1e-7;

% === IC Label ===
preprocParams.ICL.thresh = struct('eye', 0.8, ...
                                  'muscle', 0.8, ...
                                  'heart', 0.8, ...
                                  'line', 0.8, ...
                                  'chan', 0.8);

% === Bad Segments Removal ===
preprocParams.badSeg.thresh = 100; % Amplitude

