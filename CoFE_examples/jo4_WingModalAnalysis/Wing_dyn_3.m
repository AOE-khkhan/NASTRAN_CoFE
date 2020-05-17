
%% Clear memory and set path

clearvars; close all; clc
home = pwd; cd ..; cd ..; base = pwd; cd(home);
addpath(fullfile(base,'CoFE_toolbox'))

%% CASE data
inputFile = 'wing_dyn_3.bdf';
CASE = case_obj;


CASE.SOL = 101; % Solution Type
CASE.SPC = 1; % Single Point Constraint ID
CASE.LOAD = 1; % LOAD case ID
CASE.METHOD = 1; % EIGRL ID
CASE.STRESS = 1; % request stress output
CASE.STRAIN = 1; % request strain output
CASE.EKE = 1; % request element kinetic energy output
CASE.ESE = 1; % request element strain energy output
CASE.PRINT = 1; % request text output

% subcase 2
CASE(2) = CASE(1);
CASE(2).SOL = 103;


%% Run CoFE
FEM = CoFE_analysis(inputFile,CASE);

%% Post process
CoFE_view(FEM);
view(35,35)
axis equal