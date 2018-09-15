% Nastran input entry fields - delimited from input files lines.
% Constructed from BdfLines object.
%
% You must use a + or * in column 1, field 1 of a continuation entry
%
% Anthony Ricciardi
%
classdef BdfFields
    properties (SetAccess = private)
        sol % [char] Describer of the first SOL entry in the executive control section
        caseControl; % [Num Case Control Entries,1 cell].[struct] with case control describer data
%       caseControl{:}.
%                     .entryName: [char] Name of the Case Control Entry
%                     .leftHandDescribers: [char] Left hand describers
%                     .rightHandDescribers: [char] Right hand describers
        bulkData; % [Num Bulk Data Entries,1 cell] Bulk data entry fields
%                   bulkData{:} = [1,10*num continuations cell] Bulk data entry fields as [char]
    end
    methods
        function obj = BdfFields(bdfLines)
            % Reads fields from Nastran input lines stored in BdfLines object.
            obj.sol=obj.processExecutiveControl(bdfLines.executiveControl);
            obj.caseControl=obj.processCaseControl(bdfLines.caseControl);
            obj.bulkData=obj.processBulkDataLines(bdfLines.bulkData);
        end
    end
    methods (Static = true)
        function sol = processExecutiveControl(executiveControlLines)
            executiveControlFields = regexpi(executiveControlLines,...
                '\s*SOL\s+(?<rightHandDescribers>.+)','names');            
            notSolExecutiveControlFields = cellfun('isempty',executiveControlFields);
            solEntries = find(notSolExecutiveControlFields==false);
            if isempty(solEntries)
                sol = [];
            else
                firstSolEntryFields = executiveControlFields(solEntries(1));
                sol = firstSolEntryFields{1}.rightHandDescribers;
            end
        end
        function caseControlFields = processCaseControl(caseControlLines)
            nCaseControlLines = size(caseControlLines,1);
            if nCaseControlLines == 0
                caseControlFields = [];
            else
                
                % process lines other than set continuations
                caseControlRegularLines = regexpi(caseControlLines,...
                    ['\s*(?<entryName>SET)\s*(?<leftHandDescribers>\d+)\s*=\s*(?<rightHandDescribers>.+)','|',...
                    '\s*(?<entryName>\w+)\s*\((?<leftHandDescribers>.+)\)\s*=\s*(?<rightHandDescribers>.+)','|',...
                    '\s*(?<entryName>\w+)\s*=\s*(?<rightHandDescribers>.+)','|',...
                    '\s*(?<entryName>SUBCASE)\s+(?<rightHandDescribers>.+)','|'],'names');
                
                % check first line
                if isempty(caseControlRegularLines{1})
                    error('Format issue with Case Control Line: %s',caseControlLines{1})
                end
                
                % find set continuations and confirm formatting of other lines
                isSetContinuation = false(nCaseControlLines,1);
                for i  = 2:nCaseControlLines
                    if isempty(caseControlRegularLines{i})
                        previousLine = strtrim(caseControlLines{i-1});
                        if strcmp(previousLine(end),',')
                            isSetContinuation(i)=true;
                        else
                            error('Format issue with Case Control Line: %s',caseControlLines{i})
                        end
                    end
                end
                
                % Define what line continuation lines are adding to
                lineIsContinuationOf = zeros(nCaseControlLines,1,'uint32');
                continuationOfTemp = uint32(1);
                for i = 2:nCaseControlLines
                    if isSetContinuation(i)
                        lineIsContinuationOf(i) = continuationOfTemp;
                    else
                        continuationOfTemp = continuationOfTemp + 1;
                    end
                end
                clear continuationOfTemp
                
                % remove continuation lines from caseControlRegularLines
                caseControlFields = caseControlRegularLines(~isSetContinuation);
                
                % add set continuations to set entries
                fieldsLine = int32(1);
                for i = 2:nCaseControlLines
                    if isSetContinuation(i)
                        caseControlFields{fieldsLine}.rightHandDescribers=...
                            [caseControlFields{fieldsLine}.rightHandDescribers,...
                             strtrim(caseControlLines{i})];
                    else
                        fieldsLine = fieldsLine + 1;
                    end
                end
            end
        end % processCaseControl
        
        function bulkDataFields = processBulkDataLines(bulkDataLines)
            nBulkDataLines = size(bulkDataLines,1);
            lineNum = int32(1);
            entryNum = int32(1);
            fieldNum = int32(1);
            entryFields = cell(1,10);
            bulkDataFields=cell(0);
            while lineNum <= nBulkDataLines
                bulkDataLine = bulkDataLines{lineNum};
                % check if the line is a continuation
                isContinuation = any([strncmp(bulkDataLine,'+',1),strncmp(bulkDataLine,'*',1),strncmp(bulkDataLine,',',1),strncmp(bulkDataLine,'        ',8)]);
                if lineNum > 1
                    if ~isContinuation
                        bulkDataFields{entryNum,1} = strtrim(entryFields);
                        entryNum = entryNum + 1;
                        entryFields = {'','','','','','','','','',''};
                        fieldNum = int32(1);
                    else
                        fieldNum = fieldNum + 10;
                        entryFields(fieldNum:fieldNum+9)={'','','','','','','','','',''};
                    end
                end
                commas = strfind(bulkDataLine,',');
                if ~isempty(commas)
                    % free field format
                    splitLine = strsplit(bulkDataLine,',','CollapseDelimiters',false);
                    entryFields(fieldNum:fieldNum-1+size(splitLine,2))=splitLine;
                else
                    sizeBulkDataLine = size(bulkDataLine,2);
                    if sizeBulkDataLine > 7
                        asterisksFieldOne =  strfind(bulkDataLine(1:8),'*');
                    else
                        asterisksFieldOne =  strfind(bulkDataLine(1:end),'*');
                    end
                    if ~isempty(asterisksFieldOne)
                        % large field format
                        if sizeBulkDataLine >= 73
                            lineFields = {bulkDataLine(1:8),bulkDataLine(9:24),bulkDataLine(25:40),bulkDataLine(41:56),bulkDataLine(57:72)};
                        elseif sizeBulkDataLine >= 57
                            lineFields = {bulkDataLine(1:8),bulkDataLine(9:24),bulkDataLine(25:40),bulkDataLine(41:56),bulkDataLine(57:end)};
                        elseif sizeBulkDataLine >= 41
                            lineFields = {bulkDataLine(1:8),bulkDataLine(9:24),bulkDataLine(25:40),bulkDataLine(41:end),''};
                        elseif sizeBulkDataLine >= 25
                            lineFields = {bulkDataLine(1:8),bulkDataLine(9:24),bulkDataLine(25:end),'',''};
                        elseif sizeBulkDataLine >= 9
                            lineFields = {bulkDataLine(1:8),bulkDataLine(9:end),'','',''};
                        else
                            lineFields = {bulkDataLine(1:end),'','','',''};
                        end
                        entryFields(fieldNum:fieldNum+4)=lineFields;
                        
                        % check large field continuation
                        if strncmp(bulkDataLines{lineNum+1},'*',1)
                            lineNum = lineNum + 1;
                            if lineNum > nBulkDataLines
                                bulkDataFields{entryNum,1} = entryFields;
                                break
                            end
                            bulkDataLine = bulkDataLines{lineNum};
                            sizeBulkDataLine = size(bulkDataLine,2);
                            if sizeBulkDataLine >= 80
                                lineFields = {bulkDataLine(1:8),bulkDataLine(9:24),bulkDataLine(25:40),bulkDataLine(41:56),bulkDataLine(57:72),bulkDataLine(73:80)};
                            elseif sizeBulkDataLine >= 73
                                lineFields = {bulkDataLine(1:8),bulkDataLine(9:24),bulkDataLine(25:40),bulkDataLine(41:56),bulkDataLine(57:72),bulkDataLine(73:end)};
                            elseif sizeBulkDataLine >= 57
                                lineFields = {bulkDataLine(1:8),bulkDataLine(9:24),bulkDataLine(25:40),bulkDataLine(41:56),bulkDataLine(57:end),''};
                            elseif sizeBulkDataLine >= 41
                                lineFields = {bulkDataLine(1:8),bulkDataLine(9:24),bulkDataLine(25:40),bulkDataLine(41:end),'',''};
                            elseif sizeBulkDataLine >= 25
                                lineFields = {bulkDataLine(1:8),bulkDataLine(9:24),bulkDataLine(25:end),'','',''};
                            elseif sizeBulkDataLine >= 9
                                lineFields = {bulkDataLine(1:8),bulkDataLine(9:end),'','','',''};
                            else
                                lineFields = {bulkDataLine(1:end),'','','','',''};
                            end
                            entryFields(fieldNum+5:fieldNum+10)=lineFields;
                            % else
                            % entryFields(fieldNum+6:fieldNum+10)=cell(5,1);
                        end
                    else
                        % small field format
                        if sizeBulkDataLine >= 80
                            lineFields = {bulkDataLine(1:8),bulkDataLine(9:16),bulkDataLine(17:24),bulkDataLine(25:32),bulkDataLine(33:40),bulkDataLine(41:48),bulkDataLine(49:56),bulkDataLine(57:64),bulkDataLine(65:72),bulkDataLine(73:80)};
                        elseif sizeBulkDataLine >= 73
                            lineFields = {bulkDataLine(1:8),bulkDataLine(9:16),bulkDataLine(17:24),bulkDataLine(25:32),bulkDataLine(33:40),bulkDataLine(41:48),bulkDataLine(49:56),bulkDataLine(57:64),bulkDataLine(65:72),bulkDataLine(73:end)};
                        elseif sizeBulkDataLine >= 65
                            lineFields = {bulkDataLine(1:8),bulkDataLine(9:16),bulkDataLine(17:24),bulkDataLine(25:32),bulkDataLine(33:40),bulkDataLine(41:48),bulkDataLine(49:56),bulkDataLine(57:64),bulkDataLine(65:end),''};
                        elseif sizeBulkDataLine >= 57
                            lineFields = {bulkDataLine(1:8),bulkDataLine(9:16),bulkDataLine(17:24),bulkDataLine(25:32),bulkDataLine(33:40),bulkDataLine(41:48),bulkDataLine(49:56),bulkDataLine(57:end),'',''};
                        elseif sizeBulkDataLine >= 49
                            lineFields = {bulkDataLine(1:8),bulkDataLine(9:16),bulkDataLine(17:24),bulkDataLine(25:32),bulkDataLine(33:40),bulkDataLine(41:48),bulkDataLine(49:end),'','',''};
                        elseif sizeBulkDataLine >= 41
                            lineFields = {bulkDataLine(1:8),bulkDataLine(9:16),bulkDataLine(17:24),bulkDataLine(25:32),bulkDataLine(33:40),bulkDataLine(41:end),'','','',''};
                        elseif sizeBulkDataLine >= 32
                            lineFields = {bulkDataLine(1:8),bulkDataLine(9:16),bulkDataLine(17:24),bulkDataLine(25:32),bulkDataLine(33:end),'','','','',''};
                        elseif sizeBulkDataLine >= 25
                            lineFields = {bulkDataLine(1:8),bulkDataLine(9:16),bulkDataLine(17:24),bulkDataLine(25:end),'','','','','',''};
                        elseif sizeBulkDataLine >= 17
                            lineFields = {bulkDataLine(1:8),bulkDataLine(9:16),bulkDataLine(17:end),'','','','','','',''};
                        elseif sizeBulkDataLine >= 9
                            lineFields = {bulkDataLine(1:8),bulkDataLine(9:end),'','','','','','','',''};
                        else
                            lineFields = {bulkDataLine(1:end),'','','','','','','','',''};
                        end
                        entryFields(fieldNum:fieldNum+9)=lineFields;
                    end
                end
                lineNum = lineNum + 1;
            end
        end % function processBulkDataLines
        
    end
end
