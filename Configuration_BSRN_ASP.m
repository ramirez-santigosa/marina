%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% CONFIGURATION OF VARIABLES
% Version of July, 2015. L. Ramírez; At CSIRO.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION OF VARIABLES FOR THE THREATMENT OF
% BSRN SOLAR RADIATION DATA
% CASE: ALICE SPRING
% INPUT INFORMATION

%% Input data

% Specific years of threatment
year_ini = 1995; % Initial year of data
year_end = 1995; % Final year of data. Use the same initial year in case of 1 year

% Specific for Alice Spring
tzone = 9.5; % Specific time zone of the station location
owner_station = 'BOM'; % Boureau of Meterology
loc = 'ASP'; %
name = 'ALICE_SPRING_BSRN'; % ID BSRN + 00
num = '01'; % Number of the station (could be more than one station)

% General for a BSRN STATION
ref_temp = 'UTC+0'; % Time reference in which data is acquired. TST/UTCSXX (S sign, XX shift)
time_stamp = 0; % Values: 0/0.5/1 related to beginning/mid/end
num_obs = 60; % Number of observations per hour
no_data = NaN; % No data value

%% Paths definition

path_in = '..\BSRNData'; % Input data in annual folders inside: .\aaaa\
path_meteo = '..\METEOData'; % Meteo data in annual excel files
path_format = '..\OUTPUT\1_FORMAT'; % Outputs
path_qc = '..\OUTPUT\2_QC';
path_val = '..\OUTPUT\3_VALIDATION';
path_cases = '..\OUTPUT\4_CASES';
path_tmy = '..\OUTPUT\5_TMY';
path_trans = '..\OUTPUT\6_TRANS';
%! num_days_month = [31 28 31 30 31 30 31 31 30 31 30 31];
