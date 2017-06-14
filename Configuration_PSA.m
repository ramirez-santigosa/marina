%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% CONFIGURATION OF VARIABLES
% Version of July, 2015. L. Ram�rez; At CSIRO.
% Update F. Mendoza (June 2017) at CIEMAT.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION OF VARIABLES FOR THE TREATMENT OF
% PLATAFORMA SOLAR DE ALMERIA SOLAR RADIATION DATA
% CASE: PSA
% INPUT INFORMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% a - Input data
% Specific years of threatment
year_ini = 2002; % Initial year of data
year_end = 2016; % Final year of data. Use the same initial year in case of 1 year

% Specific for PSA
tzone = 1; % Specific time zone of the station location
owner_station = 'DLR'; % German Aerospace Center
loc = 'PSA'; %
name = 'ALMERIA'; % Given name
num = '01'; % Number of the station (could be more than one station)

ref_temp = 'UTC+1'; % Time reference in which data is acquired. TST/UTCSXX (S sign, XX shift)
time_stamp = 0; % Values: 0/0.5/1 related to beginning/mid/end
num_obs = 60; % Number of observations per hour
no_data = NaN; % No data value

%% b - General
num_years = year_end-year_ini+1; % Number of years
num_days_m = [31 28 31 30 31 30 31 31 30 31 30 31]; % Number of days in each month (no leap years)

%% 1 - Format
inputFormat = 'MESOR'; % Options: BSRN, MESOR, ...
header = {'YYYY','MM','DD','HH','mm','ss','GHI [W/m^2]','DNI [W/m^2]','DHI [W/m^2]',...
    't_air [degC]','rh [%]','bp [hPa]','ws [m/s]'}; % Headers of the standard structure

%% 2 - QC
vars = [1 1 1]; % Variables for QC process [GHI DNI DHI] 1(true)/0(false). Remember, for Test #3 the three variables are required.
Isc = 1367; % Solar constant [W/m2]
offset_empirical = 0; % Just in case the results seem to have timestamp mistakes
max_rad = 1600; % Max. solar radiation value for the figures

%% 3 - Validation
level = 4; % Level for validation. Defines since which flag value a day is valid according to the QC flags
max_nonvalid = 4; % Maximum number of allowed non-valid days in a month
max_dist = 5; % Maximum distance in the days used for the substitution

%% 4 - Candidates
methS = [1 1 1 1 1]; % Array for select the methodologies to apply [IEC1-SNL IEC1-LMR IEC2 DRY F-R]
num_cand = 5; % Number of candidates. Must be <= than the number of years
if num_cand > num_years
    error('The number of candidates (%d) must be less or equal to the number of years (%d).',num_cand,num_years)
end
nbins = 10; % Number of bins for cumulative distribution functions

%% 5 - Series Generation
% max_dist = 5; % Maximum distance in the days used for the substitution (usually already defined in validation)
max_times = 4; % Maximum number of times that the same day can be repeated
max_subs = 8; % Maximum number of substitutions allowed each month

% Information for SAM CSV format
sam_format = true; % Define if this file should be printed
if sam_format
    options_sam.source = owner_station;
    options_sam.locID = loc;
    options_sam.city = 'Almeria'; options_sam.reg = 'AN';
    options_sam.country = 'Spain'; % City, Region, Country
%     options_sam.lat = lat; % geodata is read from data file (lat, lon, alt)
%     options_sam.lon = lon;
    options_sam.tzone = tzone;
%     options_sam.alt = alt;

    labels{1} = 'Year'; labels{2} = 'Month'; labels{3} = 'Day'; labels{4} = 'Hour';
    labels{5} = 'Minute'; labels{6} = 'GHI'; labels{7} = 'DNI'; labels{8} = 'DHI';
    labels{9} = 'Tdry'; labels{10} = 'Tdew'; labels{11} = 'Twet'; labels{12} = 'RH';
    labels{13} = 'Pres'; labels{14} = 'Wspd';
    options_sam.labels = labels;
end

% Information for IEC 62862-1-3 format
iec_format = true; % Define if this file should be printed
if iec_format
    options_iec.hl = 25; % # of headers lines
    options_iec.characterset = slCharacterEncoding(); % Character set
    options_iec.del = 'tab'; % Delimeter
    options_iec.eol = '\n'; % End of line
    options_iec.title = [loc '00-' owner_station '-' num];
    options_iec.nowstr = datestr(datetime('now'),'yyyy-mm-ddTHH:MM:SS'); % Now string
    options_iec.histmsg = ' First test ASR data set file'; % History message
    options_iec.cmt = 'Your comment here'; % General comment
    options_iec.ds = 'synthetic'; % Data source
    options_iec.udf = 'yes'; % User defined fields
    options_iec.inst_name = owner_station; % Institution name provider
%     options_iec.lat = lat; % geodata is read from data file (lat, lon, alt)
%     options_iec.lon = lon;
%     options_iec.alt = alt;
    if tzone >= 0 % String with the time zone of the station
        timeZ = strcat('UTC+',num2str(tzone));
    else
        timeZ = strcat('UTC-',num2str(tzone));
    end
    options_iec.timezone = timeZ; % Time zone
    options_iec.t_res = 'fixed'; % Time resolution type
    options_iec.t_ave = 'no'; % Time averaging
    options_iec.t_com = 'yes'; % Time completeness
    options_iec.t_leap = 'no'; % Time calender leap years
    options_iec.nodata = no_data; % No data value
    
    labelsIEC{1} = 'time'; labelsIEC{2} = 'time_orig';
    labelsIEC{3} = 'dni'; labelsIEC{4} = 'dniqcflag';
    options_iec.labels = labelsIEC;
end

%% c - Paths definition
path_in = '..\PSAData'; % Input data in annual files
% path_meteo = '..\METEOData'; % Additional meteo data if required
path_out = '..\OUT_PSA';
path_format = [path_out '\1_FORMAT']; % Output standard data structure
path_qc = [path_out '\2_QC']; % Output Quality Control
path_val = [path_out '\3_VALIDATION']; % Output validation and gap filling
path_cases = [path_out '\4_TMYMETH']; % Output selected TMY methodology
path_tmy = [path_out '\5_ASR']; % Output annual solar radiation series