function [ scoreTable, summaryMeasureFieldName ] = surveyAnalysis_HAfreq( T )
%

subjectIDField={'SubjectID_subjectIDList'};

summaryMeasureFieldName='HAdays';

question='OnHowManyDaysInTheLast3MonthsDidYouHaveAHeadache__IfAHeadacheLa';

% Check that we have the right name for the subjectID field
subjectIDIdx=find(strcmp(T.Properties.VariableNames,subjectIDField),1);
if isempty(subjectIDIdx)
    errorText='The hard-coded subjectID field name is not present in this table';
    error(errorText);
end

% Check that we have the headache frequency question field
tmp=find(strcmp(T.Properties.VariableNames,question),1);
if isempty(tmp)
    errorText='The hard-coded headache frequency field name is not present in this table';
    error(errorText);
end

HA_freq=T.(question);

% Create a little table with the subject IDs and number of HA days in last
% 3 months
scoreTable=T(:,subjectIDIdx);
scoreTable=[scoreTable,cell2table(num2cell(HA_freq))];
scoreTable.Properties.VariableNames{2}=summaryMeasureFieldName;

end

