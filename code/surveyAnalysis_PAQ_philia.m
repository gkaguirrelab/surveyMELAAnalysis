function [ scoreTable, valuesTable, summaryMeasureFieldName ] = surveyAnalysis_PAQ_philia( T )
%
% Details regarding this measure here
%
%   Bossini, L., Fagiolini, A., Valdagno, M., Padula, L., Hofkens, T., &
%   Castrogiovanni, P. (2009). Photosensitivity in panic disorder.
%   Depression and anxiety, 26(1), E34-E36.


subjectIDField={'SubjectID'};

summaryMeasureFieldName='PAQ_philia';

questions={...
'IPreferSummerToWinterBecauseWinterDrearinessMakesMeSad_',...
'OftenInWinter_I_dLikeToGoToTheOtherHemisphereWhereItIsSummerTim',...
'MyIdealHouseHasLargeWindows_',...
'ILikeCloudyDays_',...
'IFeelRebornInSpringWhenTheDaysStartToBecomeLonger_',...
'IPreferSunlightToSemi_darkness_',...
'SunlightIsLikeTherapyForMe_',...
'IPreferWalkingInTheSunlightIfTheWeatherIsCool_',...
    };

textResponses={'Disagree',...
'Agree'};

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
% has to be done in a loop as Matlah does not have a way to address an
% array of dynamically identified field names of a structure
for qq=1:length(questions)
    T.(questions{qq})=grp2idx(categorical(T.(questions{qq}),textResponses,'Ordinal',true))+scoreOffset;
end

% Calculate the score.
% Sum (instead of nansum) is used so that the presence of any NaN values in
% the responses for a subject result in an undefined total score.
scoreMatrix=table2array(T(:,questionIndices));
sumScore=sum(scoreMatrix,2);

% The PAQ is normalized by the number of questions (so is on a scale of
% 0-1)
sumScore=sumScore/length(questions);

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

