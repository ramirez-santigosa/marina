%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%   Author: L. Ramirez, ..., F. Mendoza
%   Update: 2017
%   E-mail: ...
%   Web-site:  ...
%
% This is the main file of this toolbox. Each one of the modules is
% executed from it, according with a configuration file.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Configuration file
Configuration_BSRN_ASP

%% Module 1: To Format
MARINA10_TOFORMAT

%% Module 2: Quality Control
MARINA20_QC

%% Module 3: Qualification and Gap Filling
MARINA30_VALIDATION

%% Module 4: Candidates selection
% MARINA40_CANDIDATES

%% Module 5: Annual series generation
% MARINA50_SERIES_GENERATION

%% Module 6: Other??
% run('MARINA6_PLOTTING_DAYS');
