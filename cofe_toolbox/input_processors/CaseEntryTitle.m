% Class for TITLE Case Control entries
% Anthony Ricciardi
%
classdef CaseEntryTitle < CaseEntry
    
    properties
        name % [char]
    end
    methods
        function obj = CaseEntryTitle(entryFields)
            
            % Process left-hand-side describers
            if ~isempty(entryFields.leftHandDescribers)
                warning('TITLE case control entry should have no left-hand-side describers.')
            end
            
            % Process right-hand-side describers
            if isempty(entryFields.rightHandDescribers)
                error('Missing right hand describers for TITLE Case Control entry.')
            else
                obj.name = entryFields.rightHandDescribers;
            end

        end
        function caseControl = entry2CaseControl_sub(obj,caseControl)
            % Convert Case Control entry to property in Case Control
            caseControl.title = obj.name;
        end
        function echo_sub(obj,fid)
            % Print the case control entry in NASTRAN format to a text file with file id fid
            fprintf(fid,'TITLE = %s\n',obj.name);
        end
    end
    
    
end
