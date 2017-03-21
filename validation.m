function dataval = validation(dataqc,level,max_nonvalid)
%VALIDATION Qualifies the data of a year after QC process. A daily and
%monthly validation process are executed.
%   INPUT:
%   dataqc: Data structure after quality control process
%   level: Defines since which flag value a day is valid according to the
%   QC flags. See help QC function.
%   max_nonvalid: Maximum number of allowed non valid days in a month in
%   order to be considered a valid month.
%
%   OUTPUT:
%   dataval: Input data structure with 4 aditional fields
%       dataval.daily: Saves daily radiation values (Wh/m2) and the flags of
%       the daily validation process. Columns:
%       1 - # of the day in the month (Dia Juliano???)
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
%       dataval.replaced: Array with the replaced days along the year. Columns:
%       1 - Month
%       2 - Origin day
%       3 - Replaced day
%       dataval.nonvalid_m: Array with the number of non-valid days in each
%       month
%
% - F. Mendoza (February 2017) Update

%% Start-up
dataval = dataqc;
lat = dataval.geodata.lat;
lat_rad = lat*pi/180;
num_obs = dataval.timedata.num_obs;
year = dataval.mqc(1,1); % Get year from quality control structure

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
    
% Pre-allocation of validated daily data. Results of the daily validation
% process only include 365 days, February 29th of leap years is skipped.
% [dj GHI flag_daily_validation_GHI dj DNI flag_daily_validation_DNI] => 6 columns per year
res_daily = NaN(365,6); % Always 365!???

for dj = 1:365
    if leap && dj>59 % Skip February 29th of leap years
        num_day = dj+1;
    else
        num_day = dj;
    end
    
    % Identification of the rows of each day according with the num_obs
    lin_ini = (num_day-1)*24*num_obs+1;
    lin_end = num_day*24*num_obs;
    day = dataval.mqc(lin_ini,3); % Get number of the day in the month

    % Extraction of the dayly values
%     hour = dataval.mqc(lin_ini:lin_end,4);
%     min  = dataval.mqc(lin_ini:lin_end,5);
    GHI  = dataval.mqc(lin_ini:lin_end,7);
    fGHI = dataval.mqc(lin_ini:lin_end,8);
    DNI  = dataval.mqc(lin_ini:lin_end,9);
    fDNI = dataval.mqc(lin_ini:lin_end,10);

    % Extraction of the astronomical values
    w   = dataval.astro(lin_ini:lin_end,6); % Array of Hour angle along the day
    dec = dataval.astro(lin_ini,7); % Declination of the first instant of the day
    wsr  = acos(-tan(dec)*tan(lat_rad)); % Scalar
    wss  = -wsr; % Scalar
%     i0  = dataval.astro(lin_ini:lin_end,9); % 

    % During daytime hourly angles are less than sunrise angle (which is
    % positive) and greater than sunset angle (negative)
    pos_day = (w<wsr & w>wss); % Sun above horizon line

    % valida_days Function tests the validity of each day for each variable.
    % A day is valid if has less than an hour of abnormal data.
    [seriesG,flagG,dailyG,flagdG] = valida_days(pos_day,GHI,fGHI,num_obs,level);
    [seriesB,flagB,dailyB,flagdB] = valida_days(pos_day,DNI,fDNI,num_obs,level);

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

%% Monthly validation
% In the monthly validation, a main variable must be chosen in order to lead
% the process of nonvalid days replacement. Replacements affect all
% variables according to the main variable. Currently, DNI is the main
% variable in 'valida_months' function.

% valida_months Function tests the validity of each month for each variable
% on the basis of the daily validation results. A month is valid if has as
% much as 4 non-valid days.
[daily,monthly,replaced,nonvalid_m] = valida_months(res_daily,max_nonvalid);

dataval.daily = daily; % Update daily values if replacements were made
dataval.monthly = monthly; % Saves monthly validation results
dataval.replaced = replaced; % Array with the replaced days in the year
dataval.nonvalid_m = nonvalid_m; % Number of non-valid days in each month
end
