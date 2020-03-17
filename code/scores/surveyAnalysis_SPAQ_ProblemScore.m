function [ scoreTable, valuesTable, summaryMeasureFieldName ] = surveyAnalysis_SPAQ_ProblemScore( T )
% function [ processedTable ] = surveyAnalysis_SPAQ( T )
%
% Details regarding the SPAQ here
%
%   Rosenthal, N. E., G. H. Bradt, and T. A. Wehr. "Seasonal pattern
%   assessment questionnaire." Bethesda, MD: National Institute of Mental
%   Health (1984).
%
% This routine calculates The Global Seasonality Score (GSS) is the total
% sum of the 6 items on Question 11. This gives a score from 0 (no
% seasonality) to 24 (extreme seasonality). The average GSS in community
% samples is about 5. The average GSS in patients with SAD is about 16. The
% screening criteria for a ?diagnosis? of SAD are based on the GSS and the
% score on Question 17, the degree of problems associated with seasonal
% changes. A GSS of 11 or higher and a score on Q.17 of moderate or greater
% is indicative of SAD. As with most screening questionnaires, these
% criteria tend to overdiagnose SAD. On clinical interview, some people
% with these criteria will turn out to have subsyndromal features. On the
% other hand, very few people with a true diagnosis of SAD will be missed
% using these criteria.
%
subjectIDField={'SubjectID'};

summaryMeasureFieldName='Rosenthal_1984_SPAQ_ProblemScore';

questions={'IfYouAnsweredYesToThePreviousQuestion_PleaseSpecifyOnAScaleFrom'};

textResponses={'Does Not Apply',...
'1. Mild',...
'2. Moderate',...
'3. Marked',...
'4. Severe',...
'5. Disabling'};

% This is the offset between the index number of the textResponses
% [1, 2, 3, ...] and the assigned score value (e.g.) [0, 1, 2, ...]
scoreOffset=-1;

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
    T.(questions{qq})=grp2idx(categorical(T.(questions{qq}),textResponses,'Ordinal',true))+scoreOffset;
end

% Calculate the GSS score.
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

