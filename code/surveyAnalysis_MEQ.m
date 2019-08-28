function [ scoreTable, valuesTable, summaryMeasureFieldName ] = surveyAnalysis_MEQ( T )
% function [ processedTable ] = surveyAnalysis_MCTQ( T )
%
% MORNINGNESS-EVENINGNESS QUESTIONNAIRE (MEQ):
%
%   Horne, Jim A., and Olov �stberg. "A self-assessment questionnaire to
%   determine morningness-eveningness in human circadian rhythms."
%   International journal of chronobiology (1976).
%
% Scores can range from 16-86. Scores of 41 and below indicate ?evening types?. Scores of 59 and above indicate ?morning types?. Scores between 42 and 58 indicate ?intermediate types?.
%
% 16-30 Definite Evening
% 31-41 Moderate Evening
% 42-58 Intermediate
% 59-69 Moderate Morning
% 70-86 Definite Morning
%


subjectIDField={'SubjectID'};

summaryMeasureFieldName='Horne_1976_MEQ';

questions={'WhatTimeWouldYouGetUpIfYouWereEntirelyFreeToPlanYourDay_',...
    'WhatTimeWouldYouGoToBedIfYouWereEntirelyFreeToPlanYourEvening_',...
    'IfThereIsASpecificTimeAtWhichYouHaveToGetUpInTheMorning_ToWhatE',...
    'HowEasyDoYouFindItToGetUpInTheMorning_whenYouAreNotWokenUpUnexp',...
    'HowAlertDoYouFeelDuringTheFirstHalfHourAfterYouWakeUpInTheMorni',...
    'DuringTheFirstHalf_hourAfterYouWakeUpInTheMorning_HowTiredDoYou',...
    'IfYouHaveNoCommitmentsTheNextDay_WhatTimeWouldYouGoToBedCompare',...
    'YouHaveDecidedToEngageInSomePhysicalExercise_AFriendSuggestsTha',...
    'AtWhatTimeOfDayDoYouFeelYouBecomeTiredAsAResultOfNeedForSleep_',...
    'YouWantToBeAtYourPeakPerformanceForATestThatYouKnowIsGoingToBeM',...
    'IfYouGotIntoBedAt11_00PM_HowTiredWouldYouBe_',...
    'ForSomeReasonYouHaveGoneToBedSeveralHoursLaterThanUsual_ButTher',...
    'OneNightYouHaveToRemainAwakeBetween4_00___6_00AMInOrderToCarryO',...
    'YouHaveToDoTwoHoursOfHardPhysicalWork_YouAreEntirelyFreeToPlanY',...
    'YouHaveDecidedToEngageInHardPhysicalExercise_AFriendSuggestsTha',...
    'SupposeThatYouCanChooseYourOwnWorkHours_AssumeThatYouWorkedAFIV',...
    'AtWhatTimeOfTheDayDoYouThinkThatYouReachYour___feelingBest___Pe',...
    'OneHearsAbout___morning___And___evening___TypesOfPeople_WhichON',...
    'HowHungryDoYouFeelDuringTheFirstHalf_hourAfterYouWakeUpInTheMor'};


textResponseSets={{'Midday – 5:00 AM','11:00 AM – 12 NOON','9:45 – 11:00 AM','7:45 – 9:45 AM','6:30 – 7:45 AM','5:00 – 6:30 AM'},...
    {'3:00 AM – 8:00 PM','1:45 – 3:00 AM','12:30 – 1:45 AM','10:15 PM – 12:30 AM','9:00 – 10:15 PM','8:00 – 9:00 PM'},...
    {'Very dependent','Fairly dependent','Slightly dependent','Not at all dependent'},...
    {'Not at all easy','Not very easy','Fairly easy','Very easy'},...
    {'Not at all alert','Slightly alert','Fairly alert','Very alert'},...
    {'Very tired','Fairly tired','Fairly refreshed','Very refreshed'},...
    {'More than two hours later','1-2 hours later','Less than one hour later','Seldom or never later'},...
    {'Would find it very difficult','Would find it difficult','Would be in reasonable form','Would be in good form'},...
    {'2:00 – 3:00 AM','12:45 – 2:00 AM','10:15 PM – 12:45 AM','9:00 – 10:15 PM','8:00 – 9:00 PM'},...
    {'7:00 PM – 9:00 PM','3:00 PM – 5:00 PM','11:00 AM – 1:00 PM','8:00 AM – 10:00 AM'},...
    {'Not at all tired','A little tired','Fairly tired','Very tired'},...
    {'Will NOT wake up until later than usual','Will wake up at usual time but will fall asleep again','Will wake up at usual time and will doze thereafter','Will wake up at usual time, but will NOT fall back asleep'},...
    {'Would NOT go to bed until watch was over','Would take a nap before and sleep after','Would take a good sleep before and nap after','Would sleep only before watch'},...
    {'7:00 PM – 9:00 PM','3:00 PM – 5:00 PM','11:00 AM – 1:00 PM','8:00 AM – 10:00 AM'},...
    {'Would find it very difficult','Would find it difficult','Would be in reasonable form','Would be in good form'},...
    {'5 hours starting between 5:00 PM and 4:00 AM','5 hours starting between 2:00 PM and 5:00 PM','5 hours starting between 9:00 AM and 2:00 PM','5 hours starting between 8:00 AM and 9:00 AM','5 hours starting between 4:00 AM and 8:00 AM'},...
    {'10:00 PM – 5:00 AM','5:00 – 10:00 PM','10:00 AM – 5:00 PM','8:00 – 10:00 AM','5:00 – 8:00 AM'},...
    {'Definitely an “evening” type','Rather more an “evening” than a “morning” type','Rather more a “morning” than an “evening” type','Definitely a “morning” type'},...
    {'Not at all hungry','Slightly hungry','Fairly hungry','Very hungry'}};

% This is the offset between the index number of the textResponses
% [1, 2, 3, ...] and the assigned score value (e.g.) [0, 1, 2, ...]
scoreOffsets=    [-1,-1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0];
% One of the scores is doubled in value.
scoreMultipliers=[ 1, 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, 2,1];

% Loop through the questions and build the list of indices
for qq=1:length(questions)
    questionIdx=find(strcmp(T.Properties.VariableNames,questions{qq}),1);
    if isempty(questionIdx)
        errorText='The list of hard-coded column headings does not match the headings in the passed table';
        error(errorText);
    else
        questionIndices(qq)=questionIdx;
    end % failed to find a question header
end % loop over questions

% Check that we have the right name for the subjectID field
subjectIDIdx=find(strcmp(T.Properties.VariableNames,subjectIDField),1);
if isempty(subjectIDIdx)
    errorText='The hard-coded subjectID field name is not present in this table';
    error(errorText);
end

% Convert the text responses to integers. Sadly, this
% has to be done in a loop as Matlab does not have a way to address an
% array of dynamically identified field names of a structure

% The group2index converts the list of text responses into integer values
for qq=1:length(questions)
    idxVal = grp2idx(categorical(T.(questions{qq}),textResponseSets{qq},'Ordinal',true));
    T.(questions{qq})= (idxVal + scoreOffsets(qq))*scoreMultipliers(qq);
end

% Calculate the MEQ score.
% Sum (instead of nansum) is used so that the presence of any NaN values in
% the responses for a subject result in an undefined total score.
scoreMatrix=table2array(T(:,questionIndices));
sumScore=sum(scoreMatrix,2);

% Create a little table with the subject IDs and scores
scoreColumn = num2cell(sumScore);
scoreColumn(cellfun(@isnan,scoreColumn)) = {[]};
scoreTable=T(:,subjectIDIdx);
scoreTable=[scoreTable,cell2table(scoreColumn)];
scoreTable.Properties.VariableNames{2}=summaryMeasureFieldName;


% Create a table of the values
valuesTable=T(:,subjectIDIdx);
valuesTable=[valuesTable,T(:,questionIndices)];

end

