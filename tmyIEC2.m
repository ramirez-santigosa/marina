function [ outIEC2 ] = tmyIEC2( sourcesdata, fileOut )
%tmyIEC2 Estimates the representative long-term monthly value (RMV) based
%on several different sources of irradiation
%   INPUT:
%   sourcesdata: Array with the several sources data (12 rows as months X n
%   columns as the number of sources)
%
%   OUTPUT:
%   outIEC2: Results RMV
%   
%   TO DO function !!!
%   Example from Mora, D., Ramírez, L., Valenzuela, R.X., Polo, J., 2014.
%   Generación de series de datos para simulación de centrales termosolares
%   basadas en datos medidos. Inf. Técnicos Ciemat.

n_sources = size(sourcesdata,2);
sourceName = {'ADRASE'; 'SODA HC1'; 'SODA HC3'; 'NASA'; 'PVGIS'; 'ESTACIONES AGROCLIMATICAS'};
T = [10 10 1 10 10 10]'; % Time indicator (number of years)
D = [3 3 3 3 3 1]'; % Distance indicator (km or km2)
C = [10 20 20 100 1 5]'; % Indicates origin of data (source importance index)
% sourcesInfo = table(sourceName,T,D,C);

P = T./(D.*C); % Weight of each source
if sum(P)~=1 % Normalization weights
    P=P/sum(P);
end

% Temp variable to save the weight of each source times the monthly values of the source
PMV = zeros(size(sourcesdata)); 
for i = 1:n_sources
    PMV(:,i) = P(i)*sourcesdata(:,i);
end
RMV = sum(PMV,2); % Representative long-term monthly value

% Temp variable to save the weighted square error
PSE = zeros(size(sourcesdata)); 
for i = 1:n_sources
    PSE(:,i) = P(i)*(sourcesdata(:,i)-RMV).^2;
end
stdRMV = sqrt(sum(PSE,2));

outIEC2 = [RMV stdRMV];

outIEC2(:,1) = [85.52 102.2 149.53 179.52 211.92 231.1 239.53 210.04 159.47...
    122.01 86.27 77.92]'; % Example. Erase later.

% IEC2 TMY METHODOLOGY output report
headers_m = {'Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';'Aug';'Sep';'Oct';'Nov';'Dic'}; % Headers months
IEC2_ex = [{'', 'RMV IEC2 (kWh/m2)', 'Std Dev'}; [headers_m, num2cell(round(outIEC2,2))]];
xlswrite(fileOut,IEC2_ex,'outputIEC2','A1');

end