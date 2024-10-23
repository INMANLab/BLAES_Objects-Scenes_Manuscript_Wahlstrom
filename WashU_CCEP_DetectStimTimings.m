%% Krista Wahlstrom 11/28/23
%Extract stimulation timestamps for the single pulse electrical stimulation
%experiments with the WashU patients

%End result is a list of timestamps (at the 2K sampling rate) at which a
%stimulation occurred

%% Load BCI2000 Data

% Navigate to the BCI2000Tools folder that contains functions
% necessary for loading bci2000 data into matlab
addpath(genpath('/Users/inmanlab/Documents/MATLAB/BCI2000Tools'))

%Load the neural data (signal), behavioral data (states), sampling rates, etc. (parameters) for a single CCEP .dat file
[signal, states, param] = load_bcidat('/Users/inmanlab/Library/CloudStorage/Box-Box/INMANLab/BCI2000/BLAES Aim 2.1/CCEPs/Data/WashU_Data/BJH017/ECOGS001R23_AR4-AR5_4mA_60trials.dat');

%% Detect stimulation timings
collectThresholdCrossing = {};
iter = 1;

%Determine the exact timestamp at which the stimulation trigger begins
for i = 1:length(states.DC04)-1
    if ((states.DC04(i,1)+20) < (states.DC04((i+1),1))) %20 is an arbitrary number based on the minimum amount of increase between baseline and a stimulation trigger
        collectThresholdCrossing{iter,1} = i + 1;
        iter = iter + 1;
    end
end

%Titrate the list of detections detected above down to the correct number
%of stimulation trials
StimulationTimestamps = collectThresholdCrossing(1,1);
iter2 = 2;
for i = 1:length(collectThresholdCrossing)-1
    if (collectThresholdCrossing{i+1,1}) > (collectThresholdCrossing{i,1}+500) %500 is an arbitrary number based on the sampling rate and the known number of samples between stimulation pulses
        StimulationTimestamps{iter2,1} = collectThresholdCrossing{i+1,1};
        iter2 = iter2 + 1;
    end
end