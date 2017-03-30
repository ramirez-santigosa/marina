function [daily,monthly,replaced,nonvalid_m] = valida_months(input_daily,max_nonvalid)
%VALIDA_MONTHS Evaluates the validity of each month of a complete year (365
% days). A month is valid if has as much as 'max_nonvalid' non-valid days.
% On valid months, non-valid days are replaced with the closest day to the
% mean value. DNI is the main variable for determining replacements.
%   INPUT:
%   input_daily: Results of the daily validation of the year (output of the
%   'valida_days' function). These results always consider 365 days per year.
%   max_nonvalid: Maximum number of allowed non-valid days in a month in
%   order to be considered a valid month.
%
%   OUTPUT:
%   daily: Updated daily radiation values, if replacements were made.
%   Columns:
%       1 - # of the day in the month (Dia Juliano???)
%       2 - Daily GHI (Wh/m2). NaN if it isn't valid
%       3 - Flag daily GHI validation
%       4 - # of the day in the month
%       5 - Daily DNI (Wh/m2). NaN if it isn't valid
%       6 - Flag daily DNI validation
%   monthly: Results of the monthly validation of a specific year. Columns:
%       1 - # month
%       2 - Monthly GHI (kWh/m2). NaN if it isn't valid
%       3 - Flag monthly GHI validation
%       4 - # month
%       5 - Monthly DNI (kWh/m2). NaN if it isn't valid
%       6 - Flag monthly DNI validation
%   replaced: Replacements in a year. Columns:
%       1 - Month 
%       2 - Origin day
%       3 - Replaced day
%   replaced_month: Number of replacements in each month
%
% - F. Mendoza (March 2017) Update

%% Start-up
daily = NaN(size(input_daily));
monthly = NaN(12,1);

num_r = 0; % Number of replacements
replaced = zeros(12*max_nonvalid,3); % Pre-allocation (max number of replacements in a year)
nonvalid_m = zeros(12,1); % Pre-allocation (# of months)

%% Loop through months
for m = 1:12
    clear days_m
    first = 1+sum(num_previous_days(1:m)); % First and last rows of each month
    last = first+num_days(m)-1;
    
    % Each month block
    days_m = input_daily(first:last,1); % Day in the month
    GHI = input_daily(first:last,2)/1000; % Global irradiance [kWh/m2] and its daily validation flag
    fGHI = input_daily(first:last,3);
    DNI = input_daily(first:last,5)/1000; % Direct irradiance [kWh/m2] and its daily validation flag
    fDNI = input_daily(first:last,6);
    
    % FOCUSED on DNI analysis
    % Rare but possible, daily values == 0
    pos_nvDNI = fDNI==0; % Not valid flag ¡¡¡Value or flag?
    DNI(pos_nvDNI) = NaN;
    num_nvDNI = sum(pos_nvDNI);
    
    % Global irradiance case
    % In this case, it isn't possible that daily values == 0
    pos_nvGHI = (fGHI==0 | GHI==0);
    GHI(pos_nvGHI) = NaN;
    num_nvGHI = sum(pos_nvGHI);
    
    if num_nvDNI==0 % If all days in DNI series are valid -----------------
        rad_monthDNI = sum(DNI); % Monthly DNI is sum up of the daily values
        f_mvalDNI = 1; % Monthly flag !
        
        % GHI treatment
        if num_nvGHI==0
            rad_monthGHI = sum(GHI); % Monthly GHI is sum up of the daily values
            f_mvalGHI = 1;
        else
            % In this case, all daily DNI values are valid but some GHI
            % values aren't. GHI values cannot be replaced.
            rad_monthGHI = NaN;
            f_mvalGHI = 3; %!!! Que significaría?
        end
        
    elseif num_nvDNI<=max_nonvalid % If DNI non-valid days are less than the allowed ---
        valid = ~isnan(DNI); % Look for valid days
        rad_mean = sum(DNI(valid))/sum(valid); % Calculates monthly mean of the valid days
        [~, i_min_dist] = min(abs(DNI-rad_mean)); % Index of the day with the closest value to the mean value
        % Lo de la norma de +-5 días del día subtituido !???
        days_m(pos_nvDNI) = days_m(i_min_dist); % Replace non-valid days with the closest to the mean
        DNI(pos_nvDNI) = DNI(i_min_dist);
        rad_monthDNI = sum(DNI); % Monthly DNI is sum up of the daily values
        f_mvalDNI = 1;
        
        % GHI treatment
        % Look for GHI valid days within DNI valid indices. GHI valid values
        % must be different of zero.
        validGHI = (~isnan(GHI(valid)) & GHI(valid)~=0);
        
        if sum(validGHI)==sum(valid) % Equal number of valid days !!!Pero no implica que sean los mismos?
            % The replacements did in DNI treatment are repeated in GHI
            % treatment, it is, GHI values in the positions of non-valid
            % days in DNI series are replaced with the GHI value in the
            % position of the closest to the mean DNI daily value.
            GHI(pos_nvDNI) = GHI(i_min_dist);
            rad_monthGHI = sum(GHI); % Monthly GHI is sum up of the daily values
            f_mvalGHI = 1; % !!!
        else
            % In this case, some GHI values aren't acceptable. GHI values cannot be replaced.
            rad_monthGHI = NaN;
            f_mvalGHI = 5; % !!!
        end
        
        % Identifies replacements
        dummy = 1:length(pos_nvDNI); % Dummy array
        replaced(num_r+1:num_r+num_nvDNI,1) = ones(sum(pos_nvDNI),1)*m; % Month
        replaced(num_r+1:num_r+num_nvDNI,2) = ones(sum(pos_nvDNI),1)*days_m(i_min_dist); % Origin day
        replaced(num_r+1:num_r+num_nvDNI,3) = dummy(pos_nvDNI); % Replaced days
        num_r = num_r+num_nvDNI; % Update global number of replacements in a year
        
    else % Number of non-valid days is greater than the allowed -----------
        rad_monthDNI = NaN;
        f_mvalDNI = 0; % Non-valid month
        rad_monthGHI = NaN;
        f_mvalGHI = 7; % Non-valid month
    end
    
    % Outputs
    nonvalid_m(m,1) = num_nvDNI; % Number of non-valid days in the month
    
    % Update daily values after possible replacements
    daily(first:last,1) = days_m; % Number of the day in the month
    daily(first:last,2) = GHI*1000; % Daily GHI (Wh/m2)
    daily(first:last,3) = fGHI; % Flag daily GHI validation
    daily(first:last,4) = days_m; % Number of the day in the month
    daily(first:last,5) = DNI*1000; % Daily DNI (Wh/m2)
    daily(first:last,6) = fDNI; % Flag daily DNI validation
    
    % Save monthly results
    monthly(m,1) = m; % # month
    monthly(m,2) = rad_monthGHI; % Monthly GHI (kWh/m2)
    monthly(m,3) = f_mvalGHI; % Flag of the monthly GHI
    monthly(m,4) = m; % # month
    monthly(m,5) = rad_monthDNI; % Monthly DNI (kWh/m2)
    monthly(m,6) = f_mvalDNI; % Flag of the monthly DNI
end

replaced(num_r+1:end,:) = []; % Shrink replacements matrix

end
