%INMAN Laboratory
%Krista Wahlstrom, 2023

%This is the behavioral analysis script for BLAES Aim 2.1 for the Study
%Phase (encoding) session. 

% Stimulus codes:
% Study/Encoding images:101-720 (101-348 objects, 349-472 scenes, 473-720 scrambled) 
% Stimulation:1501 (no stim), 1502 (stim)
% Fixation cross:1601-1786
% ISI: 1801
% Instructions:1901-1905
% Sync pulse:1906

%Task progression: Sync Pulse (2s) > Instructions > Fixation > Study Image (3s) > Stim/No-Stim (1s) > ISI (5s) > Fixation (0.5-1.5s) > Study Image (3s) ...etc

clear;
close all;


addpath(genpath(fullfile(cd,'BCI2000Tools')))

subjID         = 'BJH027';
imageset       = 'imageset3';


d = dir(fullfile(cd,'data',subjID,'Study',imageset,'*.dat'));

%Don't include any .dat files with training data
removefile = [];
iter = 1;
for file = 1:size(d,1)
    if strfind(d(file).name,'Training')
        removefile(iter) = file;
        iter = iter + 1;
    end
end
d(removefile) = [];
clear removefile

%Set this to true if patient is responding as you would expect during the
%3 second presentation of the images. Set this to false, if patient did not respond
%during the presentation of the image (and instead made responses during
%the stimulation period 1501/1502 or the inter-trial ISI period 1801 or 
% during the fixation cross period 1601-1786) 
respondDuringImage = true;

%Create response string for saving separate figure files and .mat files based on which analysis is run 
if respondDuringImage == true
    ResponseString = '_RespondDurImage';
else
    ResponseString = '_RespondAftImage';
end


%Combine all .dat files for the study phase session into one matrix
iter2 = 1;
    for file = 1:size(d,1)
        
        [~, states, parameters] = load_bcidat(fullfile(d(file).folder,d(file).name));
        pause(1);

        SEQ = parameters.Sequence.NumericValue;
        KD = states.KeyDown;
        StimCode = states.StimulusCode;

        SEQ(SEQ < 101) = [];
        SEQ(SEQ > 800) = [];

        %Replaces the stimcode values that are not equal to a SEQ/image
        %stimulus code, with the previously shown image's stimulus code/SEQ
        %value if respondDuringImage is set to "false" so that keypresses
        %can be gathered from during the intertrial period
        if(~respondDuringImage)
            lastValidImage = -1;
            for i = 1:length(StimCode)
                if(lastValidImage ~= StimCode(i) && ismember(StimCode(i), SEQ))
                    lastValidImage = StimCode(i);
                elseif(lastValidImage ~= -1 && ~ismember(StimCode(i), SEQ))
                    StimCode(i) = lastValidImage;
                end
            end
        end

        %Create a copy of the keypresses file
        KDCopy = KD;
        KDCopy(KDCopy==0) = [];
        

        %Create keyPresses variable which lists the keypresses, the stimcode, and the stimcode index at which that key press occurred 
        cnt = 1;
        keyPresses = zeros(length(KDCopy), 3);
        for i = 1:length(KD)
            if(KD(i) ~= 0)
                keyPresses(cnt,1) = KD(i);
                keyPresses(cnt,2) = StimCode(i);
                keyPresses(cnt,3) = i;
                cnt = cnt + 1;
            end
        end

        %Create collectStudyData matrix of filename, stimulus code/image
        %code, image type (item/scene), key press
        for i = 1:length(SEQ)
            collectStudyData{iter2,1} = parameters.Stimuli.Value{6,SEQ(i)};
            collectStudyData{iter2,2} = SEQ(i);
            collectStudyData{iter2,3} = parameters.Stimuli.Value{9,SEQ(i)};
            
            idx = ismember(keyPresses(:,2), SEQ(i));
            keyPressesForSeq = keyPresses(idx, :);

            pressForImage = 0;
            for j = 1: size(keyPressesForSeq)
                if(pressForImage == 0)
                    pressForImage = keyPressesForSeq(j, 1);
                elseif(keyPressesForSeq(j, 1) == 37 || keyPressesForSeq(j, 1) == 39)
                    pressForImage = keyPressesForSeq(j, 1);
                end
    
                if(pressForImage == 37 || pressForImage == 39)
                    break;
                end
            end

            if pressForImage == 37
                collectStudyData{iter2,4} = 'Dislike';
            elseif pressForImage == 39
                collectStudyData{iter2,4} = 'Like';
            else
                collectStudyData{iter2,4} = 'Non-Response Key';
            end

            collectStudyData{iter2, 5} = pressForImage;
            iter2 = iter2 + 1;
        end

    end
    
    save(fullfile(cd,'data',subjID,'Study',imageset,strcat(subjID,'_Study_Data',imageset,ResponseString,'.mat')),'collectStudyData')


%% Behavioral Analysis
%Create a copy of collectStudyData so the original data is preserved. And
%within this replicate matrix, change item-scrambledA and item-scrambledB
%to "item", and change all scrambled-item and scrambled-scene values to
%"scrambled"
MemStudyData = collectStudyData;
for k = 1:size(MemStudyData,1)
    if contains(MemStudyData{k,3},'item-')
        MemStudyData{k,3} = 'item';
    elseif contains(MemStudyData{k,3},'scrambled-')
        MemStudyData{k,3} = 'scrambled';
    elseif contains(MemStudyData{k,3},'% scene')
        MemStudyData{k,3} = 'scene';
    end
end

%Change the MemStudyData matrix into a table
MemTable = cell2table(MemStudyData);


%Add all possible behavioral response options (Dislike, Like, and Non-Response Key
% to column 4 of MemTable so that in the case where a patient doesn't use
% one of those responses, they're still added to the MemCounts table below
% to be analyzed. Also (arbitrarily) add 'scene' to column 3 of MemTable because MatLab
% won't accept empty values properly and won't analyze them correctly in
% the MemCounts table.
MemTable(size(MemTable,1)+1,3) = {'scene'};
MemTable(size(MemTable,1),4) = {'Like'};
MemTable(size(MemTable,1)+1,3) = {'scene'};
MemTable(size(MemTable,1),4) = {'Dislike'};
MemTable(size(MemTable,1)+1,3) = {'scene'};
MemTable(size(MemTable,1),4) = {'Non-Response Key'};



%Get the group counts for items/scenes/scrambled and like/dislike/non responses
%IncludeEmptyGroups will also display values in the table that are zero
MemCounts = groupcounts(MemTable,{'MemStudyData3','MemStudyData4'}, 'IncludeEmptyGroups', true);


%Subtract 1 from each of the groupcounts in the MemCounts table that's
%associated with a 'scene' value, because we artificially added these
%responses in line 140 above
for l = 1:size(MemCounts,1)
    if contains(MemCounts{l,1}, 'scene')
        MemCounts{l,3} = MemCounts{l,3}-1;
    end
end


%Sort MemCounts alphabetically
MemCounts = sortrows(MemCounts,2);
MemCounts = sortrows(MemCounts,1);

%Remove the percent column from MemCounts because it's not needed for
%analysis
MemCounts.Percent = [];



%Create text for the upper corner of the bar plot that lists each
%condition and the number of responses for each
plottext = {strcat('Item Dislike: ',num2str(MemCounts{1,3})),strcat('Item Like: ',num2str(MemCounts{2,3})),...
    strcat('Item NonResp: ',num2str(MemCounts{3,3})),strcat('Scene Dislike: ',num2str(MemCounts{4,3})),...
    strcat('Scene Like: ',num2str(MemCounts{5,3})),strcat('Scene NonResp: ',num2str(MemCounts{6,3})),...
    strcat('Scrambled Dislike: ',num2str(MemCounts{7,3})),strcat('Scrambled Like: ',num2str(MemCounts{8,3})),...
    strcat('Scrambled NonResp: ',num2str(MemCounts{9,3}))};




%Plot each behavioral response condition as a percentage of the total
%images in that condition (i.e. percentage of items/scenes/scrammbled)

b = bar([(MemCounts{1,3}/(MemCounts{1,3}+MemCounts{2,3}+MemCounts{3,3}))*100;...
    (MemCounts{2,3}/(MemCounts{1,3}+MemCounts{2,3}+MemCounts{3,3}))*100;...
    (MemCounts{3,3}/(MemCounts{1,3}+MemCounts{2,3}+MemCounts{3,3}))*100;...
    (MemCounts{4,3}/(MemCounts{4,3}+MemCounts{5,3}+MemCounts{6,3}))*100;...
    (MemCounts{5,3}/(MemCounts{4,3}+MemCounts{5,3}+MemCounts{6,3}))*100;...
    (MemCounts{6,3}/(MemCounts{4,3}+MemCounts{5,3}+MemCounts{6,3}))*100;...
    (MemCounts{7,3}/(MemCounts{7,3}+MemCounts{8,3}+MemCounts{9,3}))*100;...
    (MemCounts{8,3}/(MemCounts{7,3}+MemCounts{8,3}+MemCounts{9,3}))*100;...
    (MemCounts{9,3}/(MemCounts{7,3}+MemCounts{8,3}+MemCounts{9,3}))*100]);

xlim([0 13])
ylim([0 105])

b.FaceColor = 'flat';
%Items (first 3 bars) set to color red
b.CData(1,:) = [1 0 0];
b.CData(2,:) = [1 0 0];
b.CData(3,:) = [1 0 0];
%Scene (bar 4,5,6) set to color blue
b.CData(4,:) = [0 0 1];
b.CData(5,:) = [0 0 1];
b.CData(6,:) = [0 0 1];
%Scrambled bars (bar 7,8,9) set to color black
b.CData(7,:) = [0 0 0];
b.CData(8,:) = [0 0 0];
b.CData(9,:) = [0 0 0];

%Set the plottext labels to be positioned above bar 9.6 on the xaxis, and the
%yaxis position to be at 95% of the max number of behavioral responses that
%occur
text(9.6,max(MemCounts{:,3})*0.95, plottext)
title([subjID, ' ', imageset, ' ', 'Study Phase Responses'],'fontweight','bold','fontsize',16)
xticklabels({'Item Dislike', 'Item Like','Item NonResp','Scene Dislike','Scene Like',...
    'Scene NonResp','Scrambled Dislike', 'Scrambled Like', 'Scrambled NonResp'})
xlabel('Behavioral Response','fontweight','bold','fontsize',12)
ylabel('Counts (% of respective image category)','fontweight','bold','fontsize',12)

%get current figure "gcf" for saving purposes
f = gcf;

%Save bar graph
savefile = fullfile(cd, 'figures', subjID, imageset, strcat(subjID, '_', imageset, ResponseString, '_StudyPhase_BehavioralResponses.png'));
saveas(f, savefile);