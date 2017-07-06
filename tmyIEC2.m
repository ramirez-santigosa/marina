function [ outIEC2 ] = tmyIEC2( fileIn, fileOut, IRR_m, years )
%tmyIEC2 Estimates the representative long-term monthly value (RMV) based
%on several different sources of irradiation
%   INPUT:
%   fileIn: Excel file with the. See Table 3 IEC 62862-1-2 standard.
%   fileOut: File with the results
%   IRR_m: Monthly irradiance values, according with the main variable
%   defined (GHI or DNI)
%   years: Years included in the IRR_m values
%
%   OUTPUT:
%   outIEC2: Results RMV
%   
%   TO DO function !!!
%   Example from Mora, D., Ramírez, L., Valenzuela, R.X., Polo, J., 2014.
%   Generación de series de datos para simulación de centrales termosolares
%   basadas en datos medidos. Inf. Técnicos Ciemat.

[sources_m, sources_Name, ~] = xlsread(fileIn,'Sources');
n_sources = size(sources_m,2);

[indices,~] = xlsread(fileIn,'Indices');

T = indices(1,:); % Time indicator (number of years)
D = indices(2,:); % Distance indicator (km or km2)
C = indices(3,:); % Indicates origin of data (source importance index)

P = T./(D.*C); % Weight of each source
if sum(P)~=1 % Normalization weights % TO DO. Improve
    P = P/sum(P);
end
% P = [0.03 0.02 0.002 0.003 0.34 0.60]; % Example PSA. Erase later.

% Temp variable to save the weight of each source times the monthly values of the source
PMV = zeros(size(sources_m)); 
for i = 1:n_sources
    PMV(:,i) = P(i)*sources_m(:,i);
end
RMV = sum(PMV,2); % Representative long-term monthly value

% Temp variable to save the weighted square error
PSE = zeros(size(sources_m)); 
for i = 1:n_sources
    PSE(:,i) = P(i)*(sources_m(:,i)-RMV).^2;
end
stdRMV = sqrt(sum(PSE,2));

outIEC2 = [zeros(12,1) RMV stdRMV];

% outIEC2(:,2) = [85.52 102.2 149.53 179.52 211.92 231.1 239.53 210.04 159.47...
%     122.01 86.27 77.92]'; % Example PSA. Erase later.

% outIEC2(:,3) = [7.97 8.71 11.56 14.62 14.41 7.52 9.49 15.04 7.85 7.06 6.65...
%     6.23]'; % Example PSA. Erase later.

diff = abs(IRR_m - outIEC2(:,2)); % Difference between monthly irradiance value and RMV
% [~, i_selIEC2] = min(diff,[],2); % Selected year for each month (closest month to RMV)
[~, i_selIEC2] = min(sum(diff)); % Selected year for each month (closest year to RMV)

for m = 1:12
%     outIEC2(m,1) = years(i_selIEC2(m));
    outIEC2(m,1) = years(i_selIEC2);
end

% IEC2 TMY METHODOLOGY output report
headers_m = {'Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';'Aug';'Sep';'Oct';'Nov';'Dic'}; % Headers months
IEC2_ex = [{'', 'Year', 'RMV IEC2 (kWh/m2)', 'Std Dev'}; [headers_m, num2cell(outIEC2)]];
xlswrite(fileOut,IEC2_ex,'outputIEC2','A1');

end
