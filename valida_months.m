function [daily,monthly,replaced,nonvalid_m] = valida_months(input_daily,max_nonvalid,max_dist)
%VALIDA_MONTHS Evaluates the validity of each month of a complete year (365
% days). A month is valid if has as much as 'max_nonvalid' non-valid days.
% On valid months, non-valid days are replaced with the closest day to the
% mean value. DNI is the main variable for determining replacements.
%   INPUT:
%   input_daily: Results of the daily validation of the year (output of the
%   'valida_days' function for all days in one year). These results always
%   consider 365 days per year.
%       [day dailyG flagdG day dailyB flagdB] (365X6)
%   max_nonvalid: Maximum number of allowed non-valid days in a month in
%   order to be considered a valid month.
%   max_dist: Maximum distance in the days used for the sustitution
%   (+-max_dist).
%
%   OUTPUT:
%   daily: Updated daily radiation values, if replacements were made.
%   Columns:
%       1 - # of the day in the month
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
%   nonvalid_m: Number of non-valid days in each month
%
%   Monthly validation flags:
%   0: Non-valid month...
%   1: ... TODO
%
% - F. Mendoza (March 2017) Update

%% Start-up
num_days_m = [31 28 31 30 31 30 31 31 30 31 30 31]; % Number of days in each month (no leap years)
num_previous_days = [0 cumsum(num_days_m(1:end-1))]; % Number of days previous to the month start

daily = NaN(size(input_daily));
colM = 6; monthly = NaN(12,colM);

num_r = 0; % Number of replacements
replaced = zeros(12*max_nonvalid,3); % Pre-allocation (max number of replacements in a year)
nonvalid_m = zeros(12,1); % Pre-allocation (# of months)

%% Loop through months
for m = 1:12
    clear days_m
    first = num_previous_days(m)+1; % First and last rows of each month
    last = first+num_days_m(m)-1;
    
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
    num_nvDNI = sum(pos_nvDNI); % Number of non-valid days according DNI QC flag
    
    % Global irradiance case
    % In this case, it isn't possible that daily values == 0
    pos_nvGHI = (fGHI==0 | GHI==0);
    GHI(pos_nvGHI) = NaN;
    num_nvGHI = sum(pos_nvGHI);
    
    if num_nvDNI==0 % If all days in DNI series are valid -----------------
        rad_monthDNI = sum(DNI); % Monthly DNI is sum up of the daily values
        f_mvalDNI = 1; % Monthly DNI flag !!!
        
        % GHI treatment
        if num_nvGHI==0
            rad_monthGHI = sum(GHI); % Monthly GHI is sum up of the daily values
            f_mvalGHI = 1; % Monthly GHI flag !!!
        else
            % In this case, all daily DNI values are valid but some GHI
            % values aren't. GHI values cannot be replaced.
            rad_monthGHI = NaN;
            f_mvalGHI = 3; % Monthly GHI flag !!! Que significaría?
        end
        
    elseif num_nvDNI<=max_nonvalid % If DNI non-valid days are less than the allowed ---
        validDNI = ~isnan(DNI); % Look for valid days
        rad_mean = sum(DNI(validDNI))/sum(validDNI); % Calculates monthly mean of the valid days
        
        % Look for the substitution days on the range +-max_dist days
        nvDNI_days = find(pos_nvDNI); % Non-valis days in the month
        replaced_m = zeros(num_nvDNI,3); % To save replacements in the month
        
        for i = 1:num_nvDNI
            range = false(num_days_m(m),1); % Init range (logic array)
            first_range = nvDNI_days(i)-max_dist; % Limits of the range
            last_range = nvDNI_days(i)+max_dist;
            if first_range<=0 % Verify that the limits are inside the month
                first_range = 1;
            end
            if last_range>num_days_m(m)
                last_range = num_days_m(m);
            end
            
            range(first_range:last_range) = true; % Range of days for the substitution
            range = range & validDNI; % Substract non-valids days in the range
            days_range = days_m(range); % Number of the days in the range
            
            if sum(range)==0 % Check if there are valid days for substitution
                warning('There are not valid days for substitution: Month %d, Day %d\n',m,nvDNI_days(i));
                fprintf('A large range than (+-%d) is needed.\n',max_dist);
                continue
            end
            
            [~, i_min_dist] = min(abs(DNI(range)-rad_mean)); % Index of the day with the closest value to the mean value
            
            days_m(nvDNI_days(i)) = days_range(i_min_dist); % Replace non-valid day with the closest to the mean
            DNI(nvDNI_days(i)) = DNI(days_range(i_min_dist)); % Update DNI value
            fDNI(nvDNI_days(i)) = 2; % Update the daily flag
            replaced_m(i,:) = [m days_range(i_min_dist) nvDNI_days(i)]; % Save substitutions in the month
        end
        rad_monthDNI = sum(DNI); % Monthly DNI is sum up of the daily values
        f_mvalDNI = 1; % Monthly DNI flag !!!
        
        % GHI treatment
        % Look for GHI valid days within DNI valid indices. GHI valid values
        % must be different of zero.
        validGHI = (~isnan(GHI(validDNI)) & GHI(validDNI)~=0);
        
        if sum(validGHI)==sum(validDNI) % Equal number of valid days !!!Pero no implica que sean los mismos?
            % The replacements did in DNI treatment are repeated in GHI
            % treatment, it is, GHI values in the positions of non-valid
            % days in DNI series are replaced with the GHI value in the
            % position of the closest to the mean DNI daily value.
            GHI(pos_nvDNI) = GHI(replaced_m(:,2));
            fGHI(pos_nvDNI) = 2; % Update the daily flag
            rad_monthGHI = sum(GHI); % Monthly GHI is sum up of the daily values
            f_mvalGHI = 1; % Monthly GHI flag !!!
        else
            % In this case, some GHI values aren't acceptable. GHI values cannot be replaced.
            rad_monthGHI = NaN;
            f_mvalGHI = 5; % Monthly GHI flag !!!
        end
        
        % Save replacements along the year
        replaced(num_r+1:num_r+num_nvDNI,:) = replaced_m;
        num_r = num_r+num_nvDNI; % Update global number of replacements in the year
        
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
