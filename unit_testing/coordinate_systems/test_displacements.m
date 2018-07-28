% clearvars; close all; clc
% addpath(genpath(fullfile('..','..','cofe_toolbox')));

%% Displacements in nodal displacement and basic reference frames vs nastran
ENTRY = entry.import_entries('truss_rand_coords.dat');
MODEL = ENTRY.entry2model_all();
MODEL = MODEL.preprocess();
MODEL = MODEL.assemble();
STATIC=static();
STATIC.SID = 1;
STATIC=STATIC.solve(MODEL);

% read nastran results
nastran_u_g = csvread('truss_rand_coords_u_g.csv',1,2);
nastran_u_0 = csvread('truss_rand_coords_u_0.csv',1,2);

%fprintf(1,'%d\t%E\t%E\t%E\n',[double([MODEL.NODE.ID]'),STATIC.u_g(1:6:end),STATIC.u_g(2:6:end),STATIC.u_g(3:6:end)]')
assert(max(max(abs(nastran_u_g-[STATIC.u_g(1:6:end),STATIC.u_g(2:6:end),STATIC.u_g(3:6:end)])))<1e-6)
assert(max(max(abs(nastran_u_0-[STATIC.u_0(1:6:end),STATIC.u_0(2:6:end),STATIC.u_0(3:6:end)])))<1e-6)
