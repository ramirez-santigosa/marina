%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% CONFIGURATION OF VARIABLES
% Version of July, 2015. L. Ramírez; At CSIRO.
% Update F. Mendoza (February 2017) at CIEMAT.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION OF VARIABLES FOR THE TREATMENT OF
% BSRN SOLAR RADIATION DATA
% CASE: ALICE SPRING
% INPUT INFORMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Input data
% Specific years of threatment
year_ini = 1995; % Initial year of data
year_end = 2014; % Final year of data. Use the same initial year in case of 1 year

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

%% General
num_years = year_end-year_ini+1; % Number of years
num_days_m = [31 28 31 30 31 30 31 31 30 31 30 31]; % Number of days in each month (no leap years)

%% Format
header = {'YYYY', 'MM', 'DD', 'HH', 'mm', 'ss', 'GHI', 'DNI', 'DHI'}; % Headers of the standard structure

%% QC
vars = logical([1 1 1]); % Variables for QC process [GHI DNI DHI] 1(true)/0(false)
Isc = 1367; % Solar constant [W/m2]
offset_empirical = 0; % Just in case the results seem to have timestamp mistakes
max_rad = 1600; % Max. solar radiation value for the figures

%% Validation
level = 4; % Level for validation. Defines since which flag value a day is valid according to the QC flags
max_nonvalid = 4; % Maximum number of allowed non-valid days in a month

%% Candidates
num_cand = 5; % Number of candidates. Must be <= than the number of years
if num_cand > num_years
    error('The number of candidates (%d) must be less or equal to the number of years (%d).',num_cand,num_years)
end
nbins = 10; % Number of bins for cumulative distribution function

%% Paths definition
path_in = '..\BSRNData'; % Input data in annual folders inside: .\aaaa\
path_meteo = '..\METEOData'; % Meteo data in annual excel files
path_format = '..\OUTPUT\1_FORMAT'; % Output standard data structure
path_qc = '..\OUTPUT\2_QC'; % Output Quality Control
path_val = '..\OUTPUT\3_VALIDATION'; % Output validation and gap filling
path_cases = '..\OUTPUT\4_CASES'; % Output selection methodology
path_tmy = '..\OUTPUT\5_TMY'; % Output annual series
path_trans = '..\OUTPUT\6_TRANS'; %
