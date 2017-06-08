function [dataval] = validation(dataqc,level,max_nonvalid,max_dist)
%VALIDATION Qualifies the data of one year after QC process. A daily and
%monthly validation process are executed.
%   INPUT:
%   dataqc: Data structure after quality control process
%   level: Defines since which flag value a day is valid according to the
%   QC flags. See help QC function.
%   max_nonvalid: Maximum number of allowed non valid days in a month in
%   order to be considered a valid month.
%   max_dist: Maximum distance in the days used for the substitution
%   (+-max_dist).
%
%   OUTPUT:
%   dataval: Input QC data structure with 5 aditional fields. 'mqc' matrix is
%   updated if some data is interpolated in the daily validation or if some
%   days are substituted in the monthly validation. February 29th of leap
%   years is trimmed in 'mqc' and 'astro' matrices. Added fields:
%       dataval.interp: Saves the number of interpolated data in each day
%       for GHI and DNI. It is a cell with two matrices. Columns:
%       1 - Year
%       2 - Month
%       3 - Day
%       4 - Number of interpolated data
%       dataval.daily: Saves daily radiation values (Wh/m2) and the flags of
%       the daily validation process. Columns:
%       1 - # of the day in the month
%       2 - Daily GHI (Wh/m2). NaN if it isn't valid
%       3 - Flag daily GHI validation
%       4 - # of the day in the month
%       5 - Daily DNI (Wh/m2). NaN if it isn't valid
%       6 - Flag daily DNI validation
%       dataval.monthly: Saves monthly radiation values (kWh/m2) and the
%       flags of the monthly validation process. Columns:
%       1 - # month
%       2 - Monthly GHI (kWh/m2). NaN if it isn't valid
%       3 - Flag of the monthly GHI
%       4 - # month
%       5 - Monthly DNI (kWh/m2). NaN if it isn't valid
%       6 - Flag of the monthly DNI
%       dataval.subst: Array with the substituted days along the year. Columns:
%       1 - Year
%       2 - Month
%       3 - Origin day
%       4 - Substituted day
%       dataval.nonvalid_m: Array with the number of non-valid days in each
%       month
%
% - F. Mendoza (February 2017) Update

%% Start-up
dataval = dataqc;
lat = dataval.geodata.lat; % Latitude
lat_rad = lat*pi/180; % Latitude in radians
num_obs = dataval.timedata.num_obs; % Number of observations per hour
year = dataval.mqc(1,1); % Get year from quality control structure
num_days_m = [31 28 31 30 31 30 31 31 30 31 30 31]; % Number of days in each month (no leap years)
num_previous_days = [0 cumsum(num_days_m(1:end-1))]; % Number of days previous to the month start

%% Daily Validation
if mod(year,4)~=0
    leap = false; % Common year
elseif mod(year,100)~=0
    leap = true; % Leap year
elseif mod(year,400)~=0
    leap = false; % Common year
else
    leap = true; % Leap year
end

if leap % If leap year trim February 29th
    lin_ini_Feb29 = 59*24*num_obs+1; % First observation Feb 29th
    lin_end_Feb29 = 60*24*num_obs; % Last observation Feb 29th
    dataval.mqc(lin_ini_Feb29:lin_end_Feb29,:) = [];
    dataval.astro(lin_ini_Feb29:lin_end_Feb29,:) = [];
end

% Pre-allocation of validated daily data. Results of the daily validation
% process only include 365 days, February 29th of leap years is skipped.
% [dj GHI flag_daily_validation_GHI dj DNI flag_daily_validation_DNI] => 6 columns per year
colD = 6; res_daily = NaN(365,colD); % Always 365!
interpG_y = zeros(365,4); interpB_y = zeros(365,4);
i_interG = 1; i_interB = 1; % Interpolation indices

for dj = 1:365
    % Identification of the rows of each day according with the num_obs
    lin_ini = (dj-1)*24*num_obs+1;
    lin_end = dj*24*num_obs;
    day = dataval.mqc(lin_ini,3); % Get number of the day in the month
    
    % Extraction of the dayly values
%     hour = dataval.mqc(lin_ini:lin_end,4);
%     min  = dataval.mqc(lin_ini:lin_end,5);
    GHI  = dataval.mqc(lin_ini:lin_end,7);
    fGHI = dataval.mqc(lin_ini:lin_end,8);
    DNI  = dataval.mqc(lin_ini:lin_end,9);
    fDNI = dataval.mqc(lin_ini:lin_end,10);

    % Extraction of the astronomical values
    w = dataval.astro(lin_ini:lin_end,6); % Array of Hour angle along the day
    dec = dataval.astro(lin_ini,7); % Declination of the first instant of the day
    wsr = acos(-tan(dec)*tan(lat_rad)); % Scalar sunrise
    wss = -wsr; % Scalar sunset
%     G0 = dataval.astro(lin_ini:lin_end,9); % Extraterrestrial solar radiation [W/m2]

    % During daytime hourly angles are less than sunrise angle (which is
    % positive) and greater than sunset angle (negative)
    pos_day = (w<wsr & w>wss); % Sun above horizon line
    
    % valida_days Function tests the validity of each day for each variable.
    % A day is valid if has less than an hour of abnormal data.
    [seriesG,flagG,dailyG,flagdG,interpG] = valida_days(pos_day,GHI,fGHI,num_obs,level);
    [seriesB,flagB,dailyB,flagdB,interpB] = valida_days(pos_day,DNI,fDNI,num_obs,level);
    
    if interpG>0
        m = find(dj-num_previous_days>0,1,'last');
        d = dj-num_previous_days(m);
        interpG_y(i_interG,:) = [year m d interpG];
        i_interG = i_interG+1;
    end
    if interpB>0
        m = find(dj-num_previous_days>0,1,'last');
        d = dj-num_previous_days(m);
        interpB_y(i_interB,:) = [year m d interpG];
        i_interB = i_interB+1;
    end

    % Updating data in case of interpolation in valida_days
    dataval.mqc(lin_ini:lin_end,7) = seriesG; % GHI
    dataval.mqc(lin_ini:lin_end,8) = flagG; % Flag QC GHI
    dataval.mqc(lin_ini:lin_end,9) = seriesB; % DNI
    dataval.mqc(lin_ini:lin_end,10)= flagB; % Flag DNI
    
    % Results are saved in a table of daily validation
    res_daily(dj,1) = day; % Number of the day in the month
    res_daily(dj,2) = dailyG; % Value of the daily GHI (Wh/m2)
    res_daily(dj,3) = flagdG; % Flag of the daily GHI validation process
    res_daily(dj,4) = day; % Number of the day in the month
    res_daily(dj,5) = dailyB; % Value of the daily DNI (Wh/m2)
    res_daily(dj,6) = flagdB; % Flag of the daily DNI validation process
end

% Save interpolated days
interpG_y(i_interG:end,:) = []; interpB_y(i_interB:end,:) = [];
dataval.interp = {interpG_y; interpB_y};

%% Monthly validation
% In the monthly validation, a main variable must be chosen in order to lead
% the process of nonvalid days substitution. Substitutions affect all
% variables according to the main variable. Currently, DNI is the main
% variable in 'valida_months' function.

% valida_months Function tests the validity of each month for each variable
% on the basis of the daily validation results. A month is valid if has as
% much as 4 non-valid days.
[daily,monthly,subst,nonvalid_m] = valida_months(res_daily,max_nonvalid,max_dist);
subst = [ones(size(subst,1),1)*year subst]; % Add year to substituted array

dataval.daily = daily; % Update daily values if substitutions were made
dataval.monthly = monthly; % Saves monthly validation results
dataval.subst = subst; % Array with the substituted days in the year
dataval.nonvalid_m = nonvalid_m; % Number of non-valid days in each month

%% Update radiation series
% Updating data in case of days substitutions in valida_months
for i = 1:size(subst,1)
    origin_day = subst(i,3)+num_previous_days(subst(i,2)); % To Julian day
    subst_day = subst(i,4)+num_previous_days(subst(i,2)); % To Julian day
    lin_ini_orig = (origin_day-1)*24*num_obs+1;
    lin_end_orig = origin_day*24*num_obs;
    lin_ini_repl = (subst_day-1)*24*num_obs+1;
    lin_end_repl = subst_day*24*num_obs;
    
    dataval.mqc(lin_ini_repl:lin_end_repl,1:6) = dataval.mqc(lin_ini_orig:lin_end_orig,1:6); % Date
    dataval.mqc(lin_ini_repl:lin_end_repl,7:8) = dataval.mqc(lin_ini_orig:lin_end_orig,7:8); % GHI & Flag QC GHI
    dataval.mqc(lin_ini_repl:lin_end_repl,9:10) = dataval.mqc(lin_ini_orig:lin_end_orig,9:10); % DNI & Flag QC DNI
    % To all the other meteorological variables have applied the
    % substitutions
    dataval.mqc(lin_ini_repl:lin_end_repl,11:12) = dataval.mqc(lin_ini_orig:lin_end_orig,11:12); % DHI & Flag QC DHI
    if size(dataval.mqc,2)>12
        dataval.mqc(lin_ini_repl:lin_end_repl,13:end) = dataval.mqc(lin_ini_orig:lin_end_orig,13:end); % Other meteo
    end
    % Astronomical data are not required to be substituted
%     dataval.astro(lin_ini_repl:lin_end_repl,:) = dataval.astro(lin_ini_orig:lin_end_orig,:); % Update astro
end

end
