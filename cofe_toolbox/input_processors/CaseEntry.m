% Abstract superclass for Nastran Case Control input entries
% Anthony Ricciardi
%
classdef (Abstract) CaseEntry < matlab.mixin.Heterogeneous
    methods (Abstract)
        % The class constructor must initialize entry properties using entry field data input as struct array of char 

        % Convert entry object to model object and store in model entity array
        caseControl = entry2CaseControl_sub(obj,caseControl)
    end
    
    methods (Sealed = true)
        function caseControl = entry2CaseControl(obj)
            % Convert case control entry array to CaseControl objects
            [n,m]=size(obj);
            if m > 1; error('CaseEntry.entry2CaseControl(fid) can only handle nx1 arrays of CaseEntry objects. The second dimension exceeds 1.'); end
            
            % Master case
            masterCaseControl = CaseControl;
            i = 1;
            while i<=n
                if isa(obj(i),'CaseEntrySubcase')
                    break
                end
                masterCaseControl = entry2CaseControl_sub(obj(i),masterCaseControl);
                i = i+1;
            end
            
            % Specific subcases
            subcaseIndex = 1;
            caseControl(subcaseIndex,1)=masterCaseControl;
            while i<=n
                caseControl(subcaseIndex,1) = entry2CaseControl_sub(obj(i),caseControl(subcaseIndex,1));
                i = i+1;
                if isa(obj(i),'CaseEntrySubcase')
                    subcaseIndex = subcaseIndex + 1;
                    caseControl(subcaseIndex,1) = masterCaseControl;
                end
            end
        end % entry2CaseControl(obj)
    end
    methods (Sealed = true, Static = true)
        
        function caseEntry = constructFromFields(caseControlFields)
            % construct case entry objectes from input fields
            for i = 1:size(caseControlFields,1)
                fields = caseControlFields{i};
                % convert field 1 to case-sensitive class name
                entryName =  lower(fields.entryName);
                entryName(1) = upper(entryName(1));
                % check that input entry is supported
                if exist(['CaseEntry',entryName],'class')==8
                    % Call contructor method for each entry
                    eval(['caseEntry(i,1) = CaseEntry',entryName,'(fields);']);
                else
                    warning('Case control entry %s not supported. Entry skipped.',upper(entryName))
                end
            end
        end % constructFromFields()
    end
end
