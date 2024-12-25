% The following code should FFT transform any EEG signal in a folder
% However, you need to put in 3 inputs to get the desired effect
% folder; SavePathway, Pathway

% Load in EEGLAB
cd('C:\Users\lledesma.TIMES\Documents\MATLAB\eeglab2022.0')
eeglab

% 1. Set the folder path to record the names of all the files that are done
% with preprocessing
folder = 'Y:\\STUDY 1\\All EEG Files Organized\\Preprocessed_RAW\RAW_eyes_open_and_eyes_closed_after_component_rejection\\';
files = dir(folder);

% 2. Pick pathway where you want to save the FFT data
save_pathway = 'Y:\\STUDY 1\\All EEG Files Organized\\Preprocessed_RAW\\RAW_eyes_open_and_eyes_closed_FFT\\';

% % % % % % REMAINING CODE IS AUTOMATIC % % % % % % % % 
% % % % % % Part 1: Reading in all the files in specified folder % % % % %
files = dir(folder);

% Create a for loop that keeps only real files present from the folder
AllFileNames = {};
for i = 1:length(files)
    if files(i).isdir == 0 % check if the file is not a directory
        AllFileNames{end+1} = files(i).name;
    end
end

%Use the startsWith function to find the location of where the .eeg files
eegIndx = endsWith(AllFileNames, '.set');

%Use the location of the .eeg files to extract them and save only them
eegFiles = AllFileNames(eegIndx);

% Only Eyes Open files
eegIndx = startsWith(eegFiles, 'EyesOpen');
eegFiles = eegFiles(eegIndx);

% Remove redundancies
% Only unprocessed files will be ran by the for loop below
Already_Processed_Files = dir(save_pathway);

% Create a for loop that keeps only real files present from the folder
All_Processed_Files = {};
for i = 1:length(Already_Processed_Files)
    if Already_Processed_Files(i).isdir == 0 % check if the file is not a directory
        All_Processed_Files{end+1} = Already_Processed_Files(i).name;
    end
end


% Removes the already processed files from the vector that will be input into the for loop 
for i = 1:length(eegFiles)
    for j = 1:length(All_Processed_Files)
        if strcmp(eegFiles{i}, All_Processed_Files{j})
            eegFiles{i} = [];
            break
        end
    end
end


% Remove empty cells from the vector
eegFiles = eegFiles(~cellfun('isempty',eegFiles));

% Problematic EEG files
filesToRemove = {'EyesOpen11133_RAW.set', % Error using extractfield
                 'example 2',
                  };


% Removes the remove files from the rsEEG files vector
for i = 1:length(eegFiles)
    for j = 1:length(filesToRemove)
        if strcmp(eegFiles{i}, filesToRemove{j})
            eegFiles{i} = [];
            break
        end
    end
end

% Remove empty cells from rsEEG files vector
eegFiles = eegFiles(~cellfun('isempty',eegFiles));


% % % Part 2: Running the FFT script on each eeg file % % % %
% Run an automatic version of the code for the FIRST 100 FILES!!!!

for iii = 1:length(eegFiles) 
    Current_eegFile = eegFiles{iii} %MUST BE SQUIGGLY LINE FOR SEGMENTATION TO WORK!!!!
        
    %Import data - change the name of the ID
    EEG = pop_loadset('filename',Current_eegFile,'filepath',folder);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    
    % Resample data to 250 Hz
    EEG = pop_resample( EEG, 250);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 8,'gui','off'); 

    % Segmentation
    EEG = eeg_regepochs(EEG, [4], [-2 2]);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 7,'setname','ID#_Segmented','gui','off');

    % Prerequisites
    srate = EEG.srate; % sampling rate (Hz) - ideally it is 250Hz
    duration = round(abs(EEG.xmin - EEG.xmax)); % signal duration (seconds) - ideally 4 seconds
    N = srate*duration; % total number of samples/data per segment (2nd column in matrix)
    
    % Save data into object
    data = EEG.data; % (Channels x Data x Segments )
    data = double(data); % (Channels x Data x Segments)
   
    
    % FFT - every segment of each channel/aka FFT the whole data (like a grid)
    Channel_Length = length(data(:,1,1)); 
    FFT_segments_redundant = zeros(size(data)); % An empty array
    
    for ii = 1:Channel_Length
        FFT_segments_redundant(ii,:,:) = fft(data(ii,:,:)); % FFT the data
    end
    
    abs_segments_redundant = abs(FFT_segments_redundant); % Take the absolute value
    
    % Frequency (Hz) - one segment; use this for the name
    Frequency_Hz_num = srate*(0:N/2-1)/N; % Creates labels for Hz range, which is half of the sampling rate
    cellFrequency_Hz = num2cell(Frequency_Hz_num);
    
    for i = 1:length(cellFrequency_Hz)
        cellFrequency_Hz{i} = ['x' num2str(cellFrequency_Hz{i})];
    end
    
    
    % Convert Magnitude to Power for all segments
    abs_segments = abs_segments_redundant(:,1:N/2,:); % Cut data-points by half (Redundant)
    Amplitude_segments = (abs_segments)/(N/2); % Divide data points by 2
    
    % Combine data into one segment
    Amplitude = zeros(length(Amplitude_segments(:,1,1)),length(Amplitude_segments(1,:,1))); % Empty array
    
    Segment_Length = size(Amplitude_segments(1,1,:)); 
    
    if length(Segment_Length) > 2 % Works on data that has more than one segment
    
        Segment_Length = Segment_Length(3);
        
        for ii = 1:Segment_Length
            Amplitude = Amplitude + Amplitude_segments(:,:,ii)/Segment_Length;
        end
        
        % Add Frequency_Hz labels to data
        Amp_cell = num2cell(Amplitude);
        Frequency_Hz_Amplitude = [cellFrequency_Hz; Amp_cell];
        
        % Remove columns outside 1 - 45 Hz [CHANGED TO 0.5 HZ to 45 HZ]
        Amplitude_1_45_Hz = Frequency_Hz_Amplitude(:,3:181,:);
        
        % Adding Channel Names
        % Extracting names of the channels
        
        
        % Add if statement to remove aux channels
        Channel_name_before_transposition = extractfield(EEG.chanlocs,'labels');
        
            if length(Channel_name_before_transposition) > 62
                EEG = pop_select( EEG, 'nochannel',{'Aux1','Aux2'});
            
                Channel_name_before_transposition = extractfield(EEG.chanlocs,'labels');
                Channel_name = Channel_name_before_transposition';
                Channel_lable = {'Channels'};
                Channel_name = vertcat(Channel_lable, Channel_name);
            
                % Remove bottom two rows of Amplitude (ones associated with Aux)
                Amplitude_1_45_Hz(end-1:end,:) = [];
            
                % Add Channel name to Amplitude
                Final_data = [Channel_name Amplitude_1_45_Hz];
                
                % Set working directory to save FFT data
                cd(save_pathway);
                
                % Save the data
                ID_string = eegFiles{iii};
                file.csv = strcat(ID_string,'.csv');
                
                writecell(Final_data, file.csv)
        
            else
            
                Channel_name = Channel_name_before_transposition';
                Channel_lable = {'Channels'};
                Channel_name = vertcat(Channel_lable, Channel_name);
                
                % Add Channel name to Amplitude
                Final_data = [Channel_name Amplitude_1_45_Hz];
                
                % Set working directory to save FFT data
                cd(save_pathway);
                
                % Save the data
                ID_string = eegFiles{iii};
                file.csv = strcat(ID_string,'.csv');
                
                writecell(Final_data, file.csv)
        
            end
     
    elseif length(Segment_Length) > 1 % Works on data that ONLY has one segment
    
        Segment_Length = size(Amplitude_segments(1,1,:)); 
        Segment_Length = Segment_Length(2);
    
        for ii = 1:Segment_Length
            Amplitude = Amplitude + Amplitude_segments(:,:,ii)/Segment_Length;
        end
        
        % Add Frequency_Hz labels to data
        Amp_cell = num2cell(Amplitude);
        Frequency_Hz_Amplitude = [cellFrequency_Hz; Amp_cell];
        
        % Remove columns outside 1 - 45 Hz
        Amplitude_1_45_Hz = Frequency_Hz_Amplitude(:,5:181,:);
        
        % Adding Channel Names
        % Extracting names of the channels
        
        
        % Add if statement to remove aux channels
        Channel_name_before_transposition = extractfield(EEG.chanlocs,'labels');
        
        if length(Channel_name_before_transposition) > 62
            EEG = pop_select( EEG, 'nochannel',{'Aux1','Aux2'});
        
            Channel_name_before_transposition = extractfield(EEG.chanlocs,'labels');
            Channel_name = Channel_name_before_transposition';
            Channel_lable = {'Channels'};
            Channel_name = vertcat(Channel_lable, Channel_name);
        
            % Remove bottom two rows of Amplitude (ones associated with Aux)
            Amplitude_1_45_Hz(end-1:end,:) = [];
        
            % Add Channel name to Amplitude
            Final_data = [Channel_name Amplitude_1_45_Hz];
            
            % Set working directory to save FFT data
            cd(save_pathway);
            
            % Save the data
            ID_string = eegFiles{iii};
            file.csv = strcat(ID_string,'.csv');
            
            writecell(Final_data, file.csv)
        
        else
        
            Channel_name = Channel_name_before_transposition';
            Channel_lable = {'Channels'};
            Channel_name = vertcat(Channel_lable, Channel_name);
            
            % Add Channel name to Amplitude
            Final_data = [Channel_name Amplitude_1_45_Hz];
            
            % Set working directory to save FFT data
            cd(save_pathway);
            
            % Save the data
            ID_string = eegFiles{iii};
            file.csv = strcat(ID_string,'.csv');
            
            writecell(Final_data, file.csv)
        
        end
    
    
    end
end