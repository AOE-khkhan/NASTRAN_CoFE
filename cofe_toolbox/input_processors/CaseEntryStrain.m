% Class for STRAIN Case Control entries
% Anthony Ricciardi
%
classdef CaseEntryStrain < CaseEntry & CaseEntryOutpuRequest
    
    properties
        outputRequest=OutputRequest % [OutputRequest]
    end
    methods
        function obj = CaseEntryStrain(entryFields)
            obj = obj.processDescribers(entryFields);
        end
        function caseControl = entry2CaseControl_sub(obj,caseControl)
            % Convert Case Control entry to property in Case Control
            caseControl.strain = obj.outputRequest;
        end
        function echo_sub(obj,fid)
            % Print the case control entry in NASTRAN format to a text file with file id fid
            obj.echoOutputRequest(fid,'STRAIN')
        end
    end
    
    
end
