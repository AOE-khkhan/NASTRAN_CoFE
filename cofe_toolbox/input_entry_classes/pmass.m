% Class for PMASS property entries
% Anthony Ricciardi
%
classdef pmass < entry
    
    properties
        PID1 % Property identification number. (Integer > 0)
        M1 % Value of scalar mass. (Real)
        PID2
        M2
        PID3
        M3
        PID4
        M4
    end
    
    methods (Static = true)
		% Initialize entry properties based on input file entry data in cell format
        function PMASS = initialize(data)
            PMASS=pmass;
            PMASS.PID1 = set_data('PMASS','PID1',data{2},'int',NaN,1);
            PMASS.M1 = set_data('PMASS','M1',data{3},'dec',NaN);
            PMASS.PID2 = set_data('PMASS','PID2',data{4},'int',[],1);
            PMASS.M2 = set_data('PMASS','M2',data{5},'dec',[]);
            PMASS.PID3 = set_data('PMASS','PID3',data{6},'int',[],1);
            PMASS.M3 = set_data('PMASS','M3',data{7},'dec',[]);
            PMASS.PID4 = set_data('PMASS','PID4',data{8},'int',[],1);
            PMASS.M4 = set_data('PMASS','M4',data{9},'dec',[]);
        end
    end
    methods
        % Write appropriate model object(s) based on entry data
        function MODEL = entry2model(obj,MODEL)
            P_MASS = p_mass;
            P_MASS.PID = obj.PID1;
            P_MASS.M = obj.M1;
            if ~isempty(obj.PID2)
                P_MASS(2,1).PID = obj.PID2;
                P_MASS(2,1).M = obj.M2;
                if ~isempty(obj.PID3)
                    P_MASS(3,1).PID = obj.PID3;
                    P_MASS(3,1).M = obj.M3;
                    if ~isempty(obj.PID4)
                        P_MASS(4,1).PID = obj.PID4;
                        P_MASS(4,1).M = obj.M4;
                    end
                end
            end
            MODEL.PROP = [MODEL.PROP;P_MASS];
        end
        % Print the entry in NASTRAN free field format to a text file with file id fid
        function echo(obj,fid)
            fprintf(fid,'PMASS,%d,%f,%d,%f,%d,%f,%d,%f\n',obj.PID1,obj.M1,obj.PID2,obj.M2,obj.PID3,obj.M3,obj.PID4,obj.M4);
        end
        
    end
end
