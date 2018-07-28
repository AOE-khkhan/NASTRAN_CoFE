% Class for model nodes
% Anthony Ricciardi
%
classdef node
    
    properties
        ID  % [int] Node identification number.
        CP  % [int] Identification number of coordinate system in which the location of the node is defined.
        X_P % [3,1 real] Location of the node in coordinate system CP.
        CD % [int] Identification number of coordinate system in which the displacements, degrees-offreedom, constraints, and solution vectors are defined at the node.
        PS % [7, 1 logical] Permanent single-point constraints associated with nodal degrees of freedom. PS(1:6)==true where nodal degrees of freedom are perminantly constrained. PS(7)==true when the GRID PS field is not blank (default values used when GRID PS is blank - the seventh logical is needed because GRID PS=0 can be used to remove the default constraints defined on the GRDSET entry).
        
        X_0 % [3,1 real] Location of the node in the basic coordinate system.
        T_G0 % [3,3 real] Transoformation matrix from the basic coordinate system to node deformation coordinate system (defined in CD field)
    end
    methods
        function obj = preprocess(obj,MODEL)
            % Function to preprocess nodes
            % Output:
            %        R_0g ([ngdof,ngdof] int sparse) Transformation matrix from nodal displacement reference frame to the basic reference frame
            
            [nnodes,m]=size(obj);
            if m > 1; error('node.preprocess() can only handel nx1 arrays of node objects. The second dimension exceeds 1.'); end
            
            % check that element id numbers are unique
            NIDS = [obj.ID];
            [~,ia] = unique(NIDS,'stable');
            if size(ia,1)~=nnodes
                nonunique=setxor(ia,1:nnodes);
                error('Node identification numbers should be unique. Nonunique node identification number(s): %s',sprintf('%d,',NIDS(nonunique)))
            end
            
            % Assign coordinate systems to default if unassigned
            [CPdefault,CDdefault] = obj.setgetGRDSET();
            if isempty(CPdefault); CPdefault=int32(0); end
            if isempty(CDdefault); CDdefault=int32(0); end
            for i = 1:nnodes
                if isempty(obj(i).CP); obj(i).CP=CPdefault; end
                if isempty(obj(i).CD); obj(i).CD=CDdefault; end
            end
            
            % set X_0 and T_G0 for all nodes
            CORD = MODEL.CORD;
            cordCIDs=MODEL.cordCIDs;
            
            % Loop through nodes
            for i=1:nnodes
                oi = obj(i);
                oi.X_0=CORD(oi.CP==cordCIDs).X_0(oi.X_P);
                CORD_CD = CORD(oi.CD==cordCIDs)
                oi.T_G0=CORD_CD.T_C0(CORD_CD.X_C(oi.X_0));
                obj(i)=oi;
            end
        end
        function MODEL = assemble(obj,MODEL)
            nnodes = size(obj,1);
            % Create transformation matrix from the nodal displacement
            % reference frame to the basic reference frame
            R_0g=spalloc(6*nnodes,6*nnodes,18*nnodes);
            for i = 1:nnodes
                t_0g = obj(i).T_G0.';
                R_0g(1+6*(i-1):3+6*(i-1),1+6*(i-1):3+6*(i-1))= t_0g;
                R_0g(4+6*(i-1):6+6*(i-1),4+6*(i-1):6+6*(i-1))= t_0g;
            end
            MODEL.R_0g = R_0g;
        end
        function sg = process_ps(obj)
            % Process perminant single point constraints. Returns sg [nnodes,1 logical] set.
            nnodes = size(obj,1);
            
            psGrid = [obj.PS]; % ps defined by Grid entries as [7,nnodes logical] matrix.
            % psGrid(7,:) is a [1,nnodes logical] that is true if the node ps
            % values were defined explicitly. Default values are assigned where
            % psGrid(7,:)==false, explicit values where psGrid(7,:)==true.
            
            [~,~,PSdefault]=obj.setgetGRDSET(); % load default values from GRDSET entry
            if isempty(PSdefault); PSdefault=false(6,1); end
            psDefault = repmat(PSdefault,[1,nnodes]); % arrange default ps values as [6,nnodes logical]
            
            ps = false(6,nnodes); % initialize ps matrix [6,nnodes logical]
            ps(:,psGrid(7,:))=psGrid(1:6,psGrid(7,:)); % apply explicitly defined ps values
            ps(:,~psGrid(7,:))=psDefault(:,~psGrid(7,:)); % apply default ps values
            sg = ps(:); % arrage sg set as [6*nnodes,1 logical]
        end
    end
    methods (Static=true)
        function [CPout,CDout,PSout] = setgetGRDSET(CPin,CDin,PSin)
            % Function to store static GRDSET data as a persistent variable
            persistent CPdefault;
            persistent CDdefault;
            persistent PSdefault;
            if nargin > 0
                if nargin ~= 3; error('node.setgetGRDSET() requires zero or three input arguments'); end
                if length(CPin)>1; error('length(CPin) should be = 1 or 0 (blank).'); end
                if length(CDin)>1; error('length(CDin) should be = 1 or 0 (blank).'); end
                if ~(size(PSin,1)==6 && size(PSin,2)==1); error('size(PSin) should be a [6,1]'); end
                CPdefault = CPin;
                CDdefault = CDin;
                PSdefault = PSin;
            end
            CPout=CPdefault;
            CDout=CDdefault;
            PSout=PSdefault;
        end
    end
    
end

