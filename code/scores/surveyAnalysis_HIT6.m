function [ scoreTable, valuesTable, summaryMeasureFieldName ] = surveyAnalysis_HIT6( T )
% function [ processedTable ] = surveyAnalysis_HIT6( T )
%
% HEADACHE IMPACT TEST (HIT-6):
%
%   Yang M, Rendas-Baum R, Varon SF, Kosinski M. Validation of the 
%   headache impact test (HIT-6TM) across episodic and chronic migraine. 
%   Cephalalgia. 2010;31:357?367. doi: 10.1177/0333102410379890.
%
% Scores can range from 36-78, indicating the following impact headaches
% have on the patient's life:
%
% >= 60 Severe
% 56-59 Substantial
% 50-55 Some
% <= 49 Little to None
%

subjectIDField={'SubjectID'};

summaryMeasureFieldName='HIT6';

% Add the question text here
questions={'WhenYouHaveHeadaches_HowOftenIsThePainSevere___',...
    'HowOftenDoHeadachesLimitYourAbilityToDoUsualDailyActivitiesIncl',...
    'WhenYouHaveAHeadache_HowOftenDoYouWishYouCouldLieDown___',...    
    'InThePast4Weeks_HowOftenHaveYouFeltTooTiredToDoWorkOrDailyActiv',...
    'InThePast4Weeks_HowOftenHaveYouFeltFedUpOrIrritatedBecauseOfYou',...
    'InThePast4Weeks_HowOftenDidHeadachesLimitYourAbilityToConcentra'};

textResponses={'Never',...  % 6
'Rarely',...  % 8
'Sometimes',...  % 10
'Very Often',...  % 11
'Always'};  % 13

% This is an anonymous function that converts index values to the weirdo
% scores used by the HIT6
myScore = @(x) (x.*2+4)-floor(x./4);


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
%
% We get the index of the response, and then convert this to the value
% given in scoreVals.

% The group2index converts the list of text responses into integer values
for qq=1:length(questions)
    responseIdx = grp2idx(categorical(T.(questions{qq}),textResponses,'Ordinal',true));
    T.(questions{qq})=myScore(responseIdx);
end

% Calculate the HIT6 score.
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

