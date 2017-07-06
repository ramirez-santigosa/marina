function [output_series_int,num_cases] = interpolating_holes(series,cosZ,num_obs)
%INTERPOLATING_HOLES Interpolation of the missing values of radation series
%in the following cases:
%   HOLES is a boolean 3 columns vector [GHI DNI GHI].
%   Case 1: One variable for interpolation                             Flag
%   100(1)/010(2)/001(3) Calculation from the other variables          (-1)
%   Case 2: Two variables for interpolation
%   110(4)/101(5)/011(6) 1-D interpolation of each DNI, GHI or DHI     (-2)
%                        Calculation from one interpolated variable    (-3)
%   Case 3: All variables for interpolation
%   111(7)               1-D interpolation of both DNI and GHI         (-4)
%                        DHI calculation from two interpolated vars    (-5)
%   INPUT:
%   series: Series of radiation data for interpolation
%   (365*24*num_obsX12): [YYYY MM DD HH mm ss GHI fqcGHI DNI fqcDNI DHI fqcDHI]
%   cosZ: Cosine of the solar zenith angle for each row of the input series
%   num_obs: Number of observations per hour
%
%   OUTPUT:
%   output_series_int: Interpolated input series of each variable according
%   to the possible cases.
%   num_out: Number of ocurrences of each subcase
%
% - F. Mendoza (April 2017) Update

% Dates vector, of a non-leap year in minutes
date_year_ini = floor(datenum([2015 1  1  0  0  0])*24*num_obs);
date_year_fin = floor(datenum([2015 12 31 23 59 0])*24*num_obs);
dates_year = (date_year_ini:date_year_fin)';

% Initialization of output variables
subcases = 2*3+1; % Number of subcases evaluated
output_series_int = NaN(size(series));
output_series_int(:,1:6) = series(:,1:6); % Assign the same input date
num_cases = zeros(subcases,1);

% Extract each variable
GHI = series(:,7); fGHI = series(:,8);
DNI = series(:,9); fDNI = series(:,10);
DHI = series(:,11); fDHI = series(:,12);

% HOLES creation
GHIbad = GHI<-900 | isnan(GHI);
DNIbad = DNI<-900 | isnan(DNI);
DHIbad = DHI<-900 | isnan(DHI);

HOLES = [GHIbad DNIbad DHIbad];
holes_per_row = sum(HOLES,2);

% Case 1 ------------------------------------------------------------------
case1 = holes_per_row==1; % Just one variable for interpolation
if sum(case1,1)>0
    c100 = (GHIbad & case1); % Interpolate GHI
    c010 = (DNIbad & case1); % Interpolate DNI
    c001 = (DHIbad & case1); % Interpolate DHI
    num_cases(1) = sum(c100,1); % Number of bads GHI
    num_cases(2) = sum(c010,1); % Number of bads DNI
    num_cases(3) = sum(c001,1); % Number of bads DHI
    if num_cases(1)>0 % Interpolation GHI
        GHI(c100) = (DNI(c100).*cosZ(c100))+DHI(c100);
        fGHI(c100) = -1; % Update flag
    end
    if num_cases(2)>0 % Interpolation DNI
        elev = cosZ>0.005; % Solar elevation angle > 0.3°
        c010elev = c010&elev;
        DNI(c010elev) = (GHI(c010elev)-DHI(c010elev))./cosZ(c010elev);
        DNI(~c010elev) = 0;
        fDNI(c010) = -1; % Update flag
    end
    if num_cases(3)>0 % Interpolation DHI
        DHI(c001) = GHI(c001)-(DNI(c001).*cosZ(c001));
        fDNI(c001) = -1; % Update flag
    end
end

% Case 2 ------------------------------------------------------------------
case2 = holes_per_row==2; % Two variables for interpolation
if sum(case2,1)>0
    c110 = (GHIbad & DNIbad & case2); % Interpolate GHI & DNI
    c011 = (DNIbad & DHIbad & case2); % Interpolate DNI & DHI
    c101 = (GHIbad & DHIbad & case2); % Interpolate GHI & DHI
    num_cases(4) = sum(c110,1); % Number of bads GHI & DNI
    num_cases(5) = sum(c011,1); % Number of bads DNI & DHI
    num_cases(6) = sum(c101,1); % Number of bads GHI & DHI
    if num_cases(4)>0 % Interpolation GHI & DNI
        DNI(c110) = interp1(dates_year(~DNIbad),DNI(~DNIbad),dates_year(c110));
        fDNI(c110) = -2; % Update flag
        GHI(c110) = (DNI(c110).*cosZ(c110))+DHI(c110);
        fGHI(c110) = -3; % Update flag
    end
    if num_cases(5)>0 % Interpolation DNI & DHI
        DNI(c011) = interp1(dates_year(~DNIbad),DNI(~DNIbad),dates_year(c011));
        fDNI(c011) = -2; % Update flag
        DHI(c011) = GHI(c011)-(DNI(c011).*cosZ(c011));
        fDHI(c011) = -3; % Update flag
    end
    if num_cases(6)>0 % Interpolation GHI & DHI
        GHI(c101) = interp1(dates_year(~GHIbad),GHI(~GHIbad),dates_year(c101));
        fGHI(c101) = -2; % Update flag
        DHI(c101) = GHI(c101)-(DNI(c101).*cosZ(c101));
        fDHI(c101) = -3; % Update flag
    end
end

% Case 3 ------------------------------------------------------------------
case3 = holes_per_row==3; % All variables for interpolation
if num_cases(7)>0
    c111 = case3; % Interpolate GHI, DNI & DHI
    num_cases(7) = sum(c111,1);
    GHI(c111) = interp1(dates_year(~GHIbad),GHI(~GHIbad),dates_year(c111));
    fGHI(c111) = -4; % Update flag
    DNI(c111) = interp1(dates_year(~DNIbad),DNI(~DNIbad),dates_year(c111));
    fDNI(c111) = -4; % Update flag
    DHI(c111) = GHI(c111)-(DNI(c111).*cosZ(c111));
    fDHI(c111) = -5; % Update flag
end

% Output asigment ---------------------------------------------------------
output_series_int(:,7) = round(GHI); output_series_int(:,8) = fGHI;
output_series_int(:,9) = round(DNI); output_series_int(:,10) = fDNI;
output_series_int(:,11) = round(DHI); output_series_int(:,12) = fDHI;
