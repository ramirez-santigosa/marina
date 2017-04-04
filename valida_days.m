function [output_obs,flag,daily,f_val] = valida_days(pos_day,dat,flag,num_obs,level)
%VALIDA_DAYS Evaluates the validity of a daily input data. A day is valid
%if has less than an hour of abnormal data. In that case abnormal data is
%replaced by interpolated data.
%   INPUT:
%   pos_day: Logical array of the instants between sunrise and sunset
%   dat: Array of radiation data of one day (24 h) for validation
%   flag: QC flags of the radiation according with second module process
%       (0:Non-valid, 1:Rare but possible, 2:Possible and no rare, 3:Coherent value, 4:!???)
%   num_obs: Number of observations per hour
%   level: Defines since which flag value a day is valid according to the
%   QC flags. See help QC function.
%
%   OUTPUT:
%   output_obs: Interpolated values series
%   flag: Updated quality control flag in the case of interpolated data
%   daily: Value of the daily radiation or NaN if it isn't valid
%   f_val: Flag of the dayly validation process 0: Non-valid, 1: Valid, 2: ???!!
%
% - F. Mendoza (March 2017) Update

%% Valids & Bads
valids = (flag>=level...
    & ~isnan(dat)...     % Radiation value different of NaN
    & dat~=-999)...      % Radiation value different of -999
    & pos_day;           % During daytime

% Look for the sunrise & sunset in pos_day
val_pos_day = find(pos_day);
val_pos_before_sunrise = val_pos_day(1)-1;
val_pos_after_sunset = val_pos_day(end)+1;

valids(val_pos_before_sunrise) = 1;
valids(val_pos_after_sunset) = 1;

dat(val_pos_before_sunrise) = 0;
dat(val_pos_after_sunset) = 0;

bads = pos_day & ~valids;

%% Day validation and gap filling (interpolation)
if sum(bads)==0 % No bads at all
    daily = round(sum(dat(pos_day)))/num_obs; % W/m2 per hour
    f_val = 1; % Valid day
elseif sum(bads) <= num_obs % Less than one not valid hour in the day (Interpolation)
    secuence_day = (1:24*num_obs)';
    dat(bads) = interp1(secuence_day(valids),dat(valids),secuence_day(bads)); % 1-D interpolation (table lookup)
    flag(bads) = 2; % Update of the quality control flag of the interpolated data (Possible and no rare) !!!
    % Once interpolated, calculate daily radiation
    daily = round(sum(dat(pos_day))/num_obs); % Wh/m2
    f_val = 1; % Valid day
else % More that one not valid hour in the day
    daily = NaN; % Non-valid day
    f_val = 0;
end

%% Output
if f_val==1 && daily~=0
    f_val = 2; %! ¿Que significaría el 2?
end

output_obs = zeros(24*num_obs,1);
output_obs(pos_day) = dat(pos_day);
end
