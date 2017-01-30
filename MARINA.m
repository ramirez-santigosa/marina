%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% GENERAL PROGRAM 
% Version of July, 2015. L. Ramírez; At CSIRO.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Configuration_BSRN_ASP file
run('MARINA10_TOFORMAT.m');
run('MARINA20_QC.m');
run('MARINA30_VALIDATION.m');

% run('MARINA4_CANDIDATES.m');
% run('MARINA5_SERIES_GENERATION');
% run('MARINA6_PLOTTING_DAYS');


