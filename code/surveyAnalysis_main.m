
% surveyAnalysis_main
%
% This routine loads the set of Excel files that contain the output of the
% Google Sheet demographic and survey information. The routine matches
% subject IDs across the instruments, and saves the entire set into sheets
% of an Excel file.


%% Housekeeping
clear variables
close all

[~, userName] = system('whoami');
userName = strtrim(userName);
dropboxDir = ...
    fullfile('/Users', userName, '/Dropbox (Aguirre-Brainard Lab)');

%% Set paths to surveys and output
surveyDir = '/MELA_subject/Google_Doc_Sheets/';
analysisDir = '/MELA_analysis/surveyMelanopsinAnalysis/';

% Set the output filenames
outputRawExcelName=fullfile(dropboxDir, analysisDir, 'MELA_RawSurveyData.xlsx');
outputResultExcelName=fullfile(dropboxDir, analysisDir, 'MELA_ScoresSurveyData.xlsx');

spreadSheetSet={'MELA Demographics Form v1.1 (Responses) Queried.xlsx',...
    'MELA Screening v1.1 (Responses) Queried.xlsx',...
    'MELA Vision Test Performance v1.0 Queried.xlsx',...
    'MELA Visual and Seasonal Sensitivity v1.4 (Responses) Queried.xlsx',...
    'Old version responses/v1.3/MELA Visual and Seasonal Sensitivity v1.3 (Responses) Queried.xlsx',...
    'MELA Substance and Medicine Questionnaire v1.1 (Responses) Queried.xlsx',...
    'MELA Sleep Quality Questionnaire v1.2 (Responses) Queried.xlsx',...
    'MELA Squint Post-Session Questionnaire (Responses) Queried.xlsx',...
    'MELA Headache and Comorbid Disorders Screening Form v1.0 (Responses) Queried.xlsx',...
    'MELA_Morningness Eveningness Questionnaire v1.0 (Responses) Queried.xlsx'};

handleMissingRowsFlag = [true,true,true,true,true,true,true,true,true,false];

%% Silence some expected warnings
warningState = warning;
warning('off','MATLAB:table:ModifiedAndSavedVarnames');
warning('off','MATLAB:namelengthmaxexceeded');
warning('off','MATLAB:xlswrite:AddSheet');


%% Create and save tables

% Run through once to compile the subjectIDList.
for ii=1:length(spreadSheetSet)
    spreadSheetName=fullfile(dropboxDir, surveyDir, spreadSheetSet{ii});
    T = surveyAnalysis_preProcess(spreadSheetName,handleMissingRowsFlag(ii));
    if ii==1
        subjectIDList=cell2table(T.SubjectID);
    else
        subjectIDList=outerjoin(subjectIDList,cell2table(T.SubjectID(:)));
        tmpFill=fillmissing(table2cell(subjectIDList),'nearest',2);
        subjectIDList=cell2table(tmpFill(:,1));
    end
end
subjectIDList.Properties.VariableNames{1}='SubjectID';

clear tmpFill


% Run through again and save the compiled spreadsheet
for ii=1:length(spreadSheetSet)
    spreadSheetName=fullfile(dropboxDir, surveyDir, spreadSheetSet{ii});
    [T, notesText] = surveyAnalysis_preProcess(spreadSheetName,handleMissingRowsFlag(ii));
    % Set each table to have the same subjectID list
    T = outerjoin(subjectIDList,T,'Keys','SubjectID','MergeKeys',true);
    % Write the table data
    writetable(T,outputRawExcelName,'Range','A4','WriteRowNames',true,'Sheet',ii)
    % Put the name of this spreadsheet at the top of the sheet
    writetable(cell2table(spreadSheetSet(ii)),outputRawExcelName,'WriteVariableNames',false,'Range','A1','Sheet',ii)
    % If there is noteText, write this to the table and add a warning
    if length(notesText) > 1
        writetable(cell2table(cellstr('CONVERSION WARNINGS: check bottom of sheet')),outputRawExcelName,'WriteVariableNames',false,'Range','A2','Sheet',ii)
        cornerRange=['A' strtrim(num2str(size(T,1)+7))];
        writetable(cell2table(notesText),outputRawExcelName,'WriteVariableNames',false,'Range',cornerRange,'Sheet',ii)
    end
    % Save the table into a a structure with an informative field name
    tmp=strsplit(spreadSheetSet{ii},'/');
    tmp=strsplit(tmp{end},' ');
    fieldName=strjoin(tmp(2:end),'_');
    fieldName=strrep(fieldName, '.', '_');
    fieldName=strrep(fieldName, '-', '_');
    fieldName=strrep(fieldName, '(', '_');
    fieldName=strrep(fieldName, ')', '_');
    tableFieldNames{ii}=fieldName;
    compiledTable.(tableFieldNames{ii})=T;
    clear tmp
    clear T
end


% Create a result table

% Basic demographics
functionNames = {'surveyAnalysis_age','surveyAnalysis_sex','surveyAnalysis_race','surveyAnalysis_ethnicity'};
for ii = 1:length(functionNames)
    [tmpScoreTable] = feval(functionNames{ii},compiledTable.(tableFieldNames{1}));
    if ii==1
        scoreTable=tmpScoreTable;
    else
        scoreTable=innerjoin(scoreTable,tmpScoreTable);
    end
end

% Scores
functionNames = {'surveyAnalysis_ACHOO','surveyAnalysis_conlon_VDS','surveyAnalysis_PAQ_phobia',...
    'surveyAnalysis_PAQ_philia','surveyAnalysis_SPAQ_GSS','surveyAnalysis_SPAQ_ProblemScore',...
    'surveyAnalysis_MEQ','surveyAnalysis_HAfreq'};
whichTableToPass = {[4,5],[4,5],[4,5],[4,5],[4,5],[4,5],10,9};
for ii = 1:length(functionNames)
    % obtain the table to pass
    tableSet = whichTableToPass{ii};
    for kk = 1:length(tableSet)
        thisTable = compiledTable.(tableFieldNames{tableSet(kk)});
        thisScoreTable = feval(functionNames{ii},thisTable);
        if kk == 1
            tmpScoreTable = thisScoreTable;
        else
            % Fill in missing values with the subsequent sheet
            missingVals = cellfun(@(x) isempty(x),table2cell(tmpScoreTable(:,2)));
            tmpScoreTable(missingVals,2)=thisScoreTable(missingVals,2);
        end
    end
    if ii==1
        scoreTable=innerjoin(scoreTable,tmpScoreTable);
    else
        scoreTable=innerjoin(scoreTable,tmpScoreTable);
    end
end


clear tmpScoreTable
clear tmpValuesTable

% Create some notes for the resultsTable.
notesText=cell(1,1);
notesText{1}='MELA survey analysis';
notesText{2}=['Analysis timestamp: ' datestr(datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss'))];
notesText{3}=['User: ' userName];

% Save the tables
writetable(scoreTable,outputResultExcelName,'Range','A4','WriteRowNames',true,'Sheet',1)
cornerRange=['A' strtrim(num2str(size(scoreTable,1)+7))];
writetable(cell2table(notesText'),outputResultExcelName,'WriteVariableNames',false,'Range',cornerRange,'Sheet',1)

% Restore the warning state
warning(warningState);
