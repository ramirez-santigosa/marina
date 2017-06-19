function [results,substituted,used,counter,ctrl,warn]...
    = subs_days_up(month,days_m,RMV,limit,max_dist,max_times,max_subs)
%SUBS_DAYS_UP Carry out days substitutions to increment the monthly value
%towards the Representative monthly value (RMV). Iteratively substitutes
%the day with the minimum irradiance value for a day with greater
%irradiance value until ctrl>(-limit).
%   INPUT:
%   month: Number of the evaluated month.
%   days_m: Number of the day and daily irradiance in kWh/m2.
%   RMV: Representative long term monthly value (objective value).
%   limit: Maximum difference between RMV and monthly value.
%   max_dist: Maximum distance in the days used for the substitution
%   (+-max_dist).
%   max_times: Maximum number of times that the same day may appear in the
%   generated data set.
%   max_subs: Maximum number of substitutions allowed each month.
%
%   OUTPUT:
%   results: Array with many rows as the number of days in the month, as
%   many columns as the number of made substitutions times 2. The last pair
%   of columns saves the final days and its irradiance values after all the
%   substitutions.
%   substituted: One-dimension logical array [n_days 1]
%       1: if the day has been substituted
%       0: otherwise
%   used: Two-dimension logical array [n_days # of substitutions]
%       1: if that day has been used as origin day
%       0: otherwise
%   counter: Counter of the number of substitutions carried out.
%   ctrl: Difference between the monthly value and the RMV. Control
%   variable
%   warn: If true indicates that the process finishes early due to a
%   warning alert
%
% - F. Mendoza (May 2017) Update

num_days_m = [31 28 31 30 31 30 31 31 30 31 30 31]; % Number of days in each month (no leap years)
n_days = num_days_m(month); % Number of days in this specific month
days_input = days_m(:,1); % Number of the days from the input (substitutions may already have happened)
days_ord = 1:n_days; % Sorted array with the number of the days

%% Initialize arrays
% substituted: One-dimension logical array [n_days 1]:
%       1: if the day has been substituted
%       0: if the day hasn't been substituted
substituted = days_input~=days_ord';
counter = sum(substituted); % Counter of the number of substitutions

% used: Two-dimension logical array:
%       rows: n_days
%       columns: one column per made substitution
%           1: if that day has been used as origin day
%           0: if that day hasn't been used as origin day
used_days = days_input(substituted);
used = false(n_days,numel(used_days));
for i = 1:numel(used_days)
    used(used_days(i),i) = true;
end

%% Carry out days substitutions to get closer to the objective value from the left

SUM_irrad = sum(days_m(:,2)); % Sum daily irradiance values => Monthly Value
ctrl = SUM_irrad-RMV; % Difference between the monthly value and the RMV. In this case always <0

% Initialization results array
results = days_m; % Initial positions and irradiance values

i = 0; % Number of iterations
warn = false; % Warning alert
while ctrl<(-limit) % Evaluate condition out of the limit
    i = i+1; % Update iterations number and columns
    ini_col_pos = i*2-1;
    ini_col_val = i*2;
    
    result_filter = results(:,ini_col_val).*(~substituted); % Discard previously substituted days
    result_filter(result_filter==0) = 999; % 999 instead of 0, since it is looking for a minimum
    
    [minI,i_min] = min(result_filter); % Min irradiance value and its index
    
    first_range = i_min-max_dist; % Limits of the range
    last_range = i_min+max_dist;
    if first_range<=0 % Verify that the limits are inside the month
        first_range = 1;
    end
    if last_range>n_days
        last_range = n_days;
    end
    
    range = false(n_days,1); % Init range (logic array)
    range(first_range:last_range) = true; % Range of valid days for the substitution
    
    % Sum through columns of the logic values, must be minor than max_times
    not_fully_used = (sum(used,2)<max_times);
    
    % Million dollar sentence !!!
    % Logical array that takes into account:
    % a: Must be in the range +-max_dist days
    % b: Don't be a previously substituted day
    % c: Used as origin day less that max_times
    candidates = range.*(~substituted).*not_fully_used;
    
    if sum(candidates)==0
        warning('There are not possible candidates for the substitution.\n Counter: %d, Control variable: %.2f, Limit: %.2f\n',...
            counter,abs(ctrl),limit);
        warn = true;
        break
    end
    
    % Distance to the control variable with the substitution (ctrl<0)
    dist = abs(results(:,ini_col_val)-minI+ctrl).*candidates; dist(dist==0) = 999;
    [~, optimal_i] = min(dist); % Optimal day is the one with the closest value to the control variable from the left
    
    % Next columns
    next_col_pos = i*2+1;
    next_col_val = (i+1)*2;
    % Initialization next columns of the results array
    results(:,next_col_pos) = results(:,ini_col_pos); % Positions
    results(:,next_col_val) = results(:,ini_col_val); % Daily irradiance value
    
    % Substitution
    results(i_min,next_col_pos) = results(optimal_i,ini_col_pos); % Position
    results(i_min,next_col_val) = results(optimal_i,ini_col_val); % Daily irradiance value
    
    SUM_irrad = sum(results(:,next_col_val)); % Monthly irradiance value after the last substitution
    ctrl = SUM_irrad-RMV; % Update control variable
    substituted(i_min,1) = true; % Updated substitutions array
    counter = counter+1; % Update substitutions counter
    used(:,counter) = false; % Update array with the origin days used
    used(optimal_i,counter) = true;
    
    if counter==max_subs && ctrl>limit
        warning('Maximum number of substitutions reached (%d). Control variable: %.2f, Limit: %.2f\n',...
            max_subs,abs(ctrl),limit);
        warn = true;
        break
    end 
end

end
