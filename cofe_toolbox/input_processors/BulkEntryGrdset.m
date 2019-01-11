% Class for GRDSET entry, which defines default options for fields 3, 7, 8, and 9 of all GRID entries.
% Anthony Ricciardi
%
classdef BulkEntryGrdset < BulkEntry
    
    properties
        cp % Identification number of coordinate system in which the location of the grid points are defined. (Integer >= 0 or blank)
        cd % Identification number of coordinate system in which the displacements, degrees of freedom, constraints, and solution vectors of the grid point are defined. (Integer >= 0 or blank)
        ps % Permanent single-point constraints on the grid point. (Any combination of Integers 1 through 6 with no embedded blanks, or blank.)
        seid % Superelement identification number. (Integer > 0 or blank)
    end
    
    methods
        function obj = BulkEntryGrdset(entryFields)
            % Construct using entry field data input as cell array of char           
            obj.cp = castInputField('GRDSET','CP',entryFields{3},'uint32',[],0);
            obj.cd = castInputField('GRDSET','CD',entryFields{7},'uint32',[],0);
            obj.ps = castInputField('GRDSET','PS',entryFields{8},'uint32',[]);
            obj.seid = castInputField('GRDSET','SEID',entryFields{9},'uint32',[]);
        end
    end
    methods
        function model = entry2model_sub(obj,model)
            % Convert entry object to model object and store in model entity array
            ps = [false;false;false;false;false;false];
            if ~isempty(obj.ps)
                ps(str2num(num2str(obj.ps)'))=true;
            end
            model.node.setGetGrdset(obj.cp,obj.cd,ps);
        end % entry2model_sub()
        function echo_sub(obj,fid)
            % Print the entry in NASTRAN free field format to a text file with file id fid
            fprintf(fid,'GRDSET,,%d,,,,%d,%d\n',obj.cp,obj.cd,obj.ps);
        end % echo_sub()
        
    end
end
