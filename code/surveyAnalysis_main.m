
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

%% The Squint subject list:
squintSubjects = {'MELA_0119';'MELA_0120';'MELA_0121';'MELA_0122';'MELA_0124';'MELA_0126';'MELA_0128';'MELA_0129';'MELA_0130';'MELA_0131';'MELA_0137';'MELA_0138';'MELA_0139';'MELA_0140';'MELA_0143';'MELA_0147';'MELA_0150';'MELA_0152';'MELA_0153';'MELA_0155';'MELA_0157';'MELA_0158';'MELA_0160';'MELA_0163';'MELA_0164';'MELA_0166';'MELA_0167';'MELA_0168';'MELA_0169';'MELA_0170';'MELA_0171';'MELA_0174';'MELA_0175';'MELA_0177';'MELA_0179';'MELA_0181';'MELA_0187';'MELA_0191';'MELA_0192';'MELA_0194';'MELA_0196';'MELA_0198';'MELA_0201';'MELA_0203';'MELA_0204';'MELA_0205';'MELA_0206';'MELA_0207';'MELA_0208';'MELA_0209';'MELA_0213';'MELA_0214';'MELA_0215';'MELA_0216';'MELA_0218';'MELA_0219';'MELA_0220';'MELA_0221';'MELA_0222';'MELA_0223'};

%% Set paths to surveys and output
surveyDir = '/MELA_subject/Google_Doc_Sheets/';
analysisDir = '/MELA_analysis/surveyMelanopsinAnalysis/';

% Set the output filenames
outputRawExcelName=fullfile(dropboxDir, analysisDir, 'MELA_RawSurveyData.xlsx');
outputResultExcelName=fullfile(dropboxDir, analysisDir, 'MELA_ScoresSurveyData.xlsx');
outputMatchResultExcelName=fullfile(dropboxDir, analysisDir, 'MELA_ScoresSurveyData_Squint.xlsx');

spreadSheetSet={'../MELA_Squint_Subject_Info.xlsx',...
    'MELA Demographics Form v1.1 (Responses) Queried.xlsx',...
    'MELA Screening v1.1 (Responses) Queried.xlsx',...
    'MELA Vision Test Performance v1.0 Queried.xlsx',...
    'MELA Visual and Seasonal Sensitivity v1.4 (Responses) Queried.xlsx',...
    'Old version responses/v1.3/MELA Visual and Seasonal Sensitivity v1.3 (Responses) Queried.xlsx',...
    'MELA Substance and Medicine Questionnaire v1.1 (Responses) Queried.xlsx',...
    'MELA Sleep Quality Questionnaire v1.2 (Responses) Queried.xlsx',...
    'MELA Squint Post-Session Questionnaire (Responses) Queried.xlsx',...
    'MELA Headache and Comorbid Disorders Screening Form v1.0 (Responses) Queried.xlsx',...
    'MELA_Morningness Eveningness Questionnaire v1.0 (Responses) Queried.xlsx'};

handleMissingRowsFlag = [true,true,true,true,true,true,true,true,true,true,false];

demographicTableIdx = 2;

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
    tmp=strsplit(tmp{end},{' ','_'});
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


%% Create a result table
% Diagnosis
functionNames = {'surveyAnalysis_diagnosis'};
for ii = 1:length(functionNames)
    [tmpScoreTable] = feval(functionNames{ii},compiledTable.(tableFieldNames{1}));
    if ii==1
        scoreTable=tmpScoreTable;
    else
        scoreTable=innerjoin(scoreTable,tmpScoreTable);
    end
end


% Basic demographics
functionNames = {'surveyAnalysis_age','surveyAnalysis_sex','surveyAnalysis_race','surveyAnalysis_ethnicity'};
for ii = 1:length(functionNames)
    [tmpScoreTable] = feval(functionNames{ii},compiledTable.(tableFieldNames{demographicTableIdx}));
    scoreTable=innerjoin(scoreTable,tmpScoreTable);
end

% Scores
functionNames = {'surveyAnalysis_ACHOO','surveyAnalysis_conlon_VDS','surveyAnalysis_PAQ_phobia',...
    'surveyAnalysis_PAQ_philia','surveyAnalysis_SPAQ_GSS','surveyAnalysis_SPAQ_ProblemScore',...
    'surveyAnalysis_MEQ','surveyAnalysis_HAfreq','surveyAnalysis_HIT6','surveyAnalysis_MIDAS'};
whichTableToPass = {[5,6],[5,6],[5,6],[5,6],[5,6],[5,6],11,10,10,10};
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

% Filter the scoreTable to just include the Squint subjects
squintSubjectsTable = table();
squintSubjectsTable.SubjectID = squintSubjects;
matchedScoreTable = innerjoin(scoreTable,squintSubjectsTable);

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

writetable(matchedScoreTable,outputMatchResultExcelName,'Range','A4','WriteRowNames',true,'Sheet',1)
cornerRange=['A' strtrim(num2str(size(matchedScoreTable,1)+7))];
writetable(cell2table(notesText'),outputMatchResultExcelName,'WriteVariableNames',false,'Range',cornerRange,'Sheet',1)


% Restore the warning state
warning(warningState);
