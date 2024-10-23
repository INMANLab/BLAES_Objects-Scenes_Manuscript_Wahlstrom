%INMAN Laboratory
%% Krista Wahlstrom 2022
%Determine patient behavioral responses for the post test session
%stimulation awareness test for BLAES Aim 2.1
%Patients given 10 stim trials and 10 sham trials for a total of 20 trials
%in this test

clear;
close all;


addpath(genpath(fullfile(cd,'BCI2000Tools')))

%Enter patient ID and imageset #
subjID         = 'BJH026';
imageset       = 'imageset2';


d = dir(fullfile(cd,'data',subjID,'BLAES_PostSessionStimTest',imageset,'*.dat'));


%Create counter to accurately populate the collectStimData matrix
collectStimDataRowCount = 1;
    for file = 1:size(d,1)
        
        [~, states, parameters] = load_bcidat(fullfile(d(file).folder,d(file).name));
        pause(1);

        SEQ = parameters.Sequence.NumericValue;
        StimSEQ = parameters.Sequence.NumericValue;
        KD = states.KeyDown;
        StimCode = states.StimulusCode;

        %Isolate "Do you feel the stimulation" instructions prompt for all
        %20 trials (stimulus code 3)
        SEQ(SEQ < 3) = [];
        SEQ(SEQ > 3) = [];

        %Isolate the stimulation stimulus codes (2 is stim and 1 is nostim)
        StimSEQ(StimSEQ < 1) = [];
        StimSEQ(StimSEQ > 2) = [];

       

        %Create a copy of the keypresses file with only the left and right
        %arrow presses
        KDCopy = KD;
        KDCopy(KDCopy > 39) = [];
        KDCopy(KDCopy < 37) = [];
        KDCopy(KDCopy == 38) = [];
        

                 
        %Create collectStimData matrix of stim prompt stimulus code (3),
        %stimulation stimulus code (1 or 2), response, keypress, stim or no
        %stim
        for i = 1:length(SEQ)
            collectStimData{collectStimDataRowCount,1} = SEQ(i);
            collectStimData{collectStimDataRowCount,2} = StimSEQ(i);
            
            if KDCopy(i) == 37
                collectStimData{collectStimDataRowCount,3} = 'No';
            elseif KDCopy(i) == 39
                collectStimData{collectStimDataRowCount,3} = 'Yes';
            end

            collectStimData{collectStimDataRowCount,4} = KDCopy(i);

            if StimSEQ(i) == 1
                collectStimData{collectStimDataRowCount,5} = 'No Stim';
            elseif StimSEQ(i) == 2
                collectStimData{collectStimDataRowCount,5} = 'Stim';
            end
            
            collectStimDataRowCount = collectStimDataRowCount + 1;
        end
        


    end
    
    save(fullfile(cd,'data',subjID,'BLAES_PostSessionStimTest',imageset,strcat(subjID,'_StimTest_Data', '.mat')),'collectStimData')


%% Behavioral Analysis
%Create a copy of collectStimData so the original data is preserved
StimTestData = collectStimData;


%Change the StimTestData matrix into a table
StimTable = cell2table(StimTestData);


%Add all possible behavioral response options (Yes and No)
% to column 3 of StimTable so that in the case where a patient doesn't use
% one of those responses, they're still added to the StimCounts table below
% to be analyzed. Also (arbitrarily) add 'No Stim' to column 5 of StimTable because MatLab
% won't accept empty values properly and won't analyze them correctly in
% the MemCounts table.
StimTable(size(StimTable,1)+1,3) = {'No'};
StimTable(size(StimTable,1),5) = {'No Stim'};
StimTable(size(StimTable,1)+1,3) = {'Yes'};
StimTable(size(StimTable,1),5) = {'No Stim'};




%Get the group counts for stim/no stim and yes/no responses
%IncludeEmptyGroups will also display values in the table that are zero
StimCounts = groupcounts(StimTable,{'StimTestData3','StimTestData5'}, 'IncludeEmptyGroups', true);


%Subtract 1 from each of the groupcounts in the StimCounts table that's
%associated with a 'No Stim' value, because we artificially added these
%responses above
for l = 1:size(StimCounts,1)
    if contains(StimCounts{l,2}, 'No Stim')
        StimCounts{l,3} = StimCounts{l,3}-1;
    end
end


%Sort StimCounts alphabetically
StimCounts = sortrows(StimCounts,2);
StimCounts = sortrows(StimCounts,1);

%Remove the percent column from StimCounts because it's not needed for
%analysis
StimCounts.Percent = [];



%Create text for the upper corner of the bar plot that lists each
%condition and the number of responses for each
plottext = {strcat('Stim - Yes: ',num2str(StimCounts{4,3})),strcat('Stim - No: ',num2str(StimCounts{2,3})),...
    strcat('No Stim - Yes: ',num2str(StimCounts{3,3})),strcat('No Stim - No: ',num2str(StimCounts{1,3}))};




%Plot each behavioral response condition as a percentage of the total
%images in that condition (i.e. percentage of stim/nostim)

b = bar([(StimCounts{4,3}/(10))*100;...
    (StimCounts{2,3}/(10))*100;...
    (StimCounts{3,3}/(10))*100;...
    (StimCounts{1,3}/(10))*100]);

xlim([0 6])
ylim([0 105])

b.FaceColor = 'flat';
%Stim to red
b.CData(1,:) = [1 0 0];
b.CData(2,:) = [1 0.8 0.8];
%No stim to blue
b.CData(3,:) = [0 0 1];
b.CData(4,:) = [0.6 0.8 1];


%Set the plottext label positioning
text(4.7,90, plottext, 'FontSize', 10)
title([subjID, ' ', imageset, ' ', 'Stimulation Test Responses'],'fontweight','bold','fontsize',16)
xticklabels({'Stim-Yes', 'Stim-No','NoStim-Yes','NoStim-No'})
xlabel('Response','fontweight','bold','fontsize',12)
ylabel('Counts (% of stim category)','fontweight','bold','fontsize',12)

%get current figure "gcf" for saving purposes
f = gcf;

%Save bar graph
savefile = fullfile(cd, 'figures', subjID, imageset, strcat(subjID, '_', imageset, '_StimTest_Responses.png'));
saveas(f, savefile);

