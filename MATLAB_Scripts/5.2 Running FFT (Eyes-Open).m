% Load in EEGLAB
cd('C:\Users\lledesma.TIMES\Documents\MATLAB\eeglab2022.0')
eeglab


% Set the working directory
cd('Y:\STUDY 1\All EEG Files Organized\Preprocessed_RAW')

% Specify the filename
filename = 'EEG Raw File Names3 (ready for FFT).xlsx';

% Read the data from the Excel file (Eyes-Open)
data = readtable(filename, 'Sheet', 2);


% 1. Set the folder path to record the names of all the files that are done
input_filepath = 'Y:\STUDY 1\All EEG Files Organized\Preprocessed_RAW\RAW_eyes_open_and_eyes_closed_after_component_rejection\';

% 2. Pick pathway where you want to save the FFT data (Power)
save_pathway_csv = 'Y:\STUDY 1\All EEG Files Organized\Preprocessed_RAW\CSV_eyes open and eyes closed FFT\Power\';

% 3. Pick pathway where you want to save the FFT data (LogPower)
save_pathway_csv_log = 'Y:\STUDY 1\All EEG Files Organized\Preprocessed_RAW\CSV_eyes open and eyes closed FFT\PowerLog\';



% % % % % % Part 1: Reading in all the files in specified folder % % % % %
% % % % % % REMAINING CODE IS AUTOMATIC % % % % % % % % 
fileNames = data.FileName;

% Remove redundancies
% Only unprocessed files will be ran by the for loop below
Already_Processed= dir(save_pathway_csv);

% Extract .set files
Already_Processed = {Already_Processed(contains({Already_Processed.name}, ".set")).name};
Already_Processed = erase(Already_Processed,".csv")'

% Remove files that have already been preprocessed
eegFiles = fileNames(~ismember(fileNames,Already_Processed));


% % % Part 2: Running the FFT script on each eeg file % % % %
% Run an automatic version of the code for the FIRST 100 FILES!!!!

for iii = 1:length(eegFiles) 


    Current_eegFile = eegFiles{iii} %MUST BE SQUIGGLY LINE FOR SEGMENTATION TO WORK!!!!
        
    %Import data - change the name of the ID
    EEG = pop_loadset('filename',Current_eegFile,'filepath',input_filepath);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    
    % Segmentation
    EEG = eeg_regepochs(EEG, [4], [-2 2]);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 7,'setname','ID#_Segmented','gui','off');

    % Save data into object
    A = EEG.data;
    
    % Quality Control
    fs = EEG.srate;

    Channel_Num = size(A,1);
    N = size(A,2);
    Segment_Num = size(A,3);

    freq = 0:fs/N:fs-1/fs;

    % Run FFT then take the absolute power of each channel in a segment and
    % then for all segments. 
    Power_Output = zeros(size(A(:,1:N/2+1,:))); % An empty 3-dimensional array
    Power_OutputLog = zeros(size(A(:,1:N/2+1,:)));
    
    for iii = 1:Segment_Num

        for ii = 1:Channel_Num

            % Extract current row (channel) of current segment
            xn = A(ii,:,iii);
    
            % Calculate power
            xk = (1/N^2)*abs(fft(xn)).^2; % Two-sided power
            xk = xk(1:N/2+1); % One-sided
            xk(2:end-1) = 2*xk(2:end-1); % Double values except for DC and Nyquist
    
            % Save this 
            Power_Output(ii,:,iii) = xk;

            % Convert power to dB
            xk_dB = 10 * log10(xk);
    
            % Save this too
            Power_OutputLog(ii,:,iii) = xk_dB;

        end

    end

    
    % Average all FFT data across segments into one
    Power_Output_Avg = mean(Power_Output,3);
    Power_OutputLog_Avg = mean(Power_OutputLog,3);

    % Save the frequency associated with FFT data
    frequency = freq(1:N/2+1);
    frequency_string = "x" + string(frequency);

    % Create Tables to save this data
    Table1 = array2table(Power_Output_Avg, 'VariableNames', frequency_string);
    Table2 = array2table(Power_OutputLog_Avg, 'VariableNames', frequency_string);
         
    % Introduce Channel variable
    Table1.Channels = extractfield(EEG.chanlocs,'labels')';
    Table2.Channels = extractfield(EEG.chanlocs,'labels')';
    
    % Save the files (respectively)
    cd(save_pathway_csv);
    writetable(Table1, [Current_eegFile '.csv']);

    cd(save_pathway_csv_log);
    writetable(Table2, [Current_eegFile '.csv']);
    
       
end