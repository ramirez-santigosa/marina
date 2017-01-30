%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% GENERAL PROGRAM 
% Version of January, 2017. L. Ramírez, F. Mendoza; At CIEMAT.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Configuration_BSRN_ASP file
run('MARINA10_TOFORMAT.m');
run('MARINA20_QC.m');
run('MARINA30_VALIDATION.m');

% run('MARINA4_CANDIDATES.m');
% run('MARINA5_SERIES_GENERATION');
% run('MARINA6_PLOTTING_DAYS');


