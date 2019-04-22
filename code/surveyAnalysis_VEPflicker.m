
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
localDir=fullfile('/Users', userName, '/Documents/MATLAB/Carlyn');

%% Set paths to surveys and output
surveyDir = '/MELA_subject/Google_Doc_Sheets/';
analysisDir = '/MELA_subject/vepMELAanalysis/';

% Identify the spreadsheets and subjects
spreadSheetSet={'MELA Demographics Form.xlsx',...
    'MELA Headache and Comorbid Disorders Screening Form.xlsx'};

subjectSet={'MELA_0120';'MELA_0121';'MELA_0131';'MELA_0167';'MELA_0169';...
    'MELA_0170';'MELA_0174';'MELA_0175';'MELA_0179';'MELA_0181';...
    'MELA_0187';'MELA_0191';'MELA_0194'};


%% Create and save tables

% Compile the subjectIDList
subjectIDList=cell2table(subjectSet);
subjectIDList.Properties.VariableNames{1}='SubjectID';

% Turn off warnings about adding a sheet to the Excel file
warnID='MATLAB:xlswrite:AddSheet';
orig_state = warning;
warning('off',warnID);

% Run through again and save the compiled spreadsheet
for i=1:length(spreadSheetSet)
    spreadSheetName=fullfile(localDir, spreadSheetSet{i});
    [T, notesText] = surveyAnalysis_preProcess(spreadSheetName);
    % Set each table to have the same subjectID list
    T = outerjoin(subjectIDList,T);
   
    % Save the table into a structure with an informative field name
    tmp=strsplit(spreadSheetSet{i},' ');
    fieldName=strjoin(tmp(2:length(tmp)),'_');
    fieldName=strrep(fieldName, '.', '_');
    fieldName=strrep(fieldName, '(', '_');
    fieldName=strrep(fieldName, ')', '_');
    tableFieldNames{i}=fieldName;
    compiledTable.(tableFieldNames{i})=T;
    clear tmp
    clear T
end


% restore warning state
warning(orig_state);

% Create a result table
% add age
[tmpScoreTable,tmpValuesTable] = surveyAnalysis_age(compiledTable.(tableFieldNames{1}));
scoreTable=tmpScoreTable;
valuesTable=tmpValuesTable;

% add gender
[tmpScoreTable,tmpValuesTable] = surveyAnalysis_sex(compiledTable.(tableFieldNames{1}) );
scoreTable=innerjoin(scoreTable,tmpScoreTable);

% add race and ethnicity
[tmpScoreTable,tmpValuesTable] = surveyAnalysis_race(compiledTable.(tableFieldNames{1}) );
scoreTable=innerjoin(scoreTable,tmpScoreTable);

[tmpScoreTable,tmpValuesTable] = surveyAnalysis_ethnicity(compiledTable.(tableFieldNames{1}) );
scoreTable=innerjoin(scoreTable,tmpScoreTable);

% % add visual discomfort score
% [tmpScoreTable, tmpValuesTable] = surveyAnalysis_choi_phobia( compiledTable.(tableFieldNames{4}) );
% scoreTable=innerjoin(scoreTable,tmpScoreTable);

% add headache frequency
[tmpScoreTable,tmpValuesTable]=surveyAnalysis_HAfreq(compiledTable.(tableFieldNames{2}));
scoreTable=innerjoin(scoreTable,tmpScoreTable);

clear tmpScoreTable
clear tmpValuesTable


save vepMELA_subjectInfo scoreTable