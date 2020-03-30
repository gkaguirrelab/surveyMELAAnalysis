function [ scoreTable, valuesTable, summaryMeasureFieldName ] = surveyAnalysis_MIDAS( T )
% function [ processedTable ] = surveyAnalysis_MIDAS( T )
%
% THE MIGRAINE DISABILITY ASSESSMENT (MIDAS):
% 
%   Stewart WF, Lipton RB, Dowson AJ, Sawyer J. Development and testing 
%   of the Migraine Disability Assessment (MIDAS) Questionnaire to assess 
%   headache-related disability. Neurology 2001; 56: 20?28.
% 
% Scores are interpreted as follows:
%
% 0-5 Little to no disability
% 6-10 Mild disability
% 11-20 Moderate disability
% 21+ Severe disability
%
% *citation for the survey*

subjectIDField={'SubjectID'};

summaryMeasureFieldName='MIDAS';

% Add the question text here
questions={'OnHowManyDaysInTheLast3MonthsDidYouMissWorkOrSchoolBecauseOfYou',...
    'HowManyDaysInTheLast3MonthsWasYourProductivityAtWorkOrSchoolRed',...
    'OnHowManyDaysInTheLast3MonthsDidYouNotDoHouseholdWork_suchAsHou',...    
    'HowManyDaysInTheLast3MonthsWasYourProductivityInHouseholdWorkRe',...
    'OnHowManyDaysInTheLast3MonthsDidYouMissFamily_SocialOrLeisureAc'};

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

% Calculate the MIDAS score.
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

