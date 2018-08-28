% Class that defines a finite element model.
% Anthony Ricciardi
classdef model
        
    properties
        %% Model entities
        CORD@cord;
        MAT@mat;
        PROP@prop;
        NODE@node;
        ELEM@elem;
        SPCS@spcs;
%         MPCS@mpcs;
        LOADS@loads;
        
        %% Simple entities
        eigTab=[]; % [:,2 int] table with eigenvalue solver parameters [SID,ND], where SID = Set identification number and ND = number of roots desired.
        
        %% Sets and related
        sb % ([ngdof,num SID] logical) Degrees-of-freedom eliminated by single-point constraints that are included in boundary conditions
        sd % ([ngdof,num SID] sparse real) Enforced displacement values due to single-point constraints that are included in boundary conditions
        sg % ([ngdof,1] logical) Degrees-of-freedom eliminated by single-point constraints that are specified on the PS field on node entries.
        s  % ([ngdof,1] logical) All degrees-of-freedom eliminated by single point constraints -> sb + sg
        f  % ([ngdof,1] logical) Unconstrained (free) structural degrees-of-freedom -> a + o 
        m  % ([ngdof,1] logical) All degrees-of-freedom eliminated by multiple constraints
        n  % ([ngdof,1] logical) All degrees-of-freedom not constrained by multipoint constraints
        
        %% Matricies
        K_g  % ([ngdof,ngdof] sparse) Elastic stiffness matrix in nodal displacement reference frame
        KD_g % ([ngdof,ngdof] sparse) Differential stiffness matrix in nodal displacement reference frame
        M_g  % ([ngdof,ngdof] sparse) Mass matrix in nodal displacement reference frame
        G
        p_g % ([ngdof,1] real) load vector in nodal displacement reference frame
        R_0g % ([ngdof,ngdof] int sparse) Transformation matrix from nodal displacement reference frame to the basic reference frame
        
    end
    properties (Hidden=true)
        cordCIDs
        matMIDs
        propPIDs
        nodeIDs
        elemEIDs
        spcsSIDs
        loadsSIDs
        
        node2gdof
        ngdof
    end

    methods
        function obj = preprocess(obj)
            nnodes = size(obj.NODE,1);
            obj.ngdof       = 6*nnodes;
            obj.node2gdof   = zeros(6,nnodes);
            obj.node2gdof(:)= 1:obj.ngdof;
            
            % Preprocess coordinate systems
            obj.CORD = obj.CORD.preprocess_all();
            
            % Store vectors of ID numbers as seperate varables. This speeds 
            % up assembly because concatenation gets expensive.        
            obj.cordCIDs=[obj.CORD.CID]; 
            obj.matMIDs=[obj.MAT.MID]';
            obj.propPIDs=[obj.PROP.PID]';
            obj.nodeIDs=[obj.NODE.ID]';
            obj.elemEIDs=[obj.ELEM.EID]';
            obj.loadsSIDs=unique([obj.LOADS.SID])';
            
            % Preprocess remaining model entities
            obj.MAT  = obj.MAT.preprocess();
            obj.PROP = obj.PROP.preprocess();
            obj.NODE = obj.NODE.preprocess(obj);
            obj.ELEM = obj.ELEM.preprocess();
            obj.LOADS = obj.LOADS.preprocess(obj);
            
            % Process single-point constraints
            obj.sg = obj.NODE.process_ps(); % DOF eliminated by perminant single-point constraints
            [obj.sb,obj.sd,obj.spcsSIDs]=obj.SPCS.process_sb(obj.node2gdof); % SID numbers and DOF eliminated by boundary single-point constraints      
            
            % define sets (in progress)
            obj.s = obj.sg | obj.sb;
            obj.f = ~obj.s;
        end
        function obj = assemble(obj)
            
            % Process MAT references in PROP entries to speed things up?
            
            % Assemble
            obj = obj.NODE.assemble(obj);
            obj = obj.ELEM.assemble(obj); % element and global matricies
            obj = obj.LOADS.assemble(obj);
            
        end
    end
    
end

