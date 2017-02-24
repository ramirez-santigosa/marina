function [astro,tst_num,UTC_num] = calcula_astro...
    (date_num,stamp,num_obs,timeZ,lat,lon,offset_empirical)
%CALCULA_ASTRO Convert the input hour to TST and calculates in the centered
%instant.
%   INPUT:
%   date_num: Array of input serial date numbers for calculations
%   stamp: 0/0.5/1 related to beginning/mid/end of the observation period
%   num_obs: Number of observations per hour
%   timeZ: Time zone of the station location: TST/UTCSXX (S sign, XX shift)
%   lat: Latitude of the station
%   lon: Longitude of the station
%   offset_empirical: Just in case the results seem to have timestamp mistakes
%
%   OUTPUT:
%   astro: 10 columns vector
%          [dj e0 ang_day et tst_hours w dec cosz i0 m]
%   tst_num: 
%   UTC_num: 
%
% - F. Mendoza (February 2017) Update

%% Intro
lat_rad = lat*pi/180; % Latitude in radians
Isc = 1367; % Solar constant [W/m2]

% Centers the instant on the middle of the observation period for
% astronomical calculations
switch stamp
    case 0 % beginning of the interval
        date_num_center = date_num+(0.5/(24*num_obs)); 
    case 0.5 % middle of the interval
        date_num_center = date_num;
    case 1 % end of the interval
        date_num_center = date_num-(0.5/(24*num_obs));
    otherwise
        date_num_center = date_num;
        warning('Unexpected value for stamp in calcula_astro.m')
end

date_vec_center = datevec(date_num_center);

%% Astronomical calculations
% Dayly (TST assumed) !!!
dj = floor(date_num)-datenum(date_vec_center(:,1),1,1)+1; % Number of the day of each observation
e0 = 1+0.033*cos(2*pi*dj/365); % Sun-Earth distance correction factor
ang_day = double(2*pi*(dj-1)/365); % Day angle
et = 229.18*(0.000075+0.001868*cos(ang_day)-0.032077*sin(ang_day)...
    -0.014615*cos(2*ang_day)-0.04089*sin(2*ang_day)); % Equation of time

% Consider this if not TST
sumGMT2TST = ((et./60)+(lon/15))./24; % Days
time_corr = NaN(length(sumGMT2TST),1);

% Analyzes real situation
if strcmp(timeZ(1:3),'TST')
    off = 0;
    time_corr(:) = 0;
elseif strcmp(timeZ(1:3),'UTC')
    off = str2double(timeZ(4:end));
    time_corr = sumGMT2TST;
else
    off = 0;
    warning('Unexpected value of the time zone for the station location in calcula_astro.m')
end

tst_num = date_num_center+time_corr-(off/24)+offset_empirical/24;

tst_hours = (tst_num-floor(tst_num))*24; % Hours (decimals)
w = (12-tst_hours)*15*pi/180; % 
dec = 0.006918-0.399912*cos(ang_day)+0.070257*sin(ang_day)...
      -0.006758*cos(2*ang_day)+0.000907*sin(2*ang_day)...
      -0.002697*cos(3*ang_day)+0.00148*sin(3*ang_day); %
cosz = sin(dec).*sin(lat_rad)+cos(dec).*cos(lat_rad).*cos(w); % Cosine of the solar zenith angle

i0 = Isc.*e0.*cosz; % 
pos_neg = find(i0<=0);
pos_pos = find(i0>0);
i0(pos_neg) = 0; % If negative, turn into zero

m = zeros(size(dj));
m(pos_neg) = max(m(pos_pos));
m(pos_pos) = 1./(cosz(pos_pos)+0.50572.*(96.07995-(acos(cosz(pos_pos)).*180/pi)).^-1.6364); %

%% Output

% Dates converted back to UTC at the beginning of the interval
UTC_num = tst_num-sumGMT2TST-(offset_empirical/24)-(0.5/(num_obs*24)); %
astro   = double([dj e0 ang_day et tst_hours w dec cosz i0 m]);
