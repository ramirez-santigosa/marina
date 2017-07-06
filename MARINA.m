%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%   Author: L. Ramirez, ..., F. Mendoza
%   Update: 2017
%   E-mail: lourdes.ramirez@ciemat.es
%   Web-site: solrea.ceta-ciemat.es
%
% This is the main file of this toolbox. Each one of the modules is
% executed from it, according with a configuration file.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Configuration file
% cfgFile = 'Configuration_BSRN_ASP.m';
cfgFile = 'Configuration_PSA.m';

%% Module 1: To Format
MARINA10_TOFORMAT

%% Module 2: Quality Control
MARINA20_QC

%% Module 3: Validation and Gap Filling
MARINA30_VALIDATION

%% Module 4: Typical meteorological months selection (TMY methodologies)
MARINA40_TMYMETH

%% Module 5: Annual series generation
MARINA50_SERIES_GENERATION

%% Module 6: Adding other meteorological data
% MARINA60_ADDING_METEO_DATA
