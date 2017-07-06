function [headers, meteonormData] = read_MeteoData(filename, num_obs_meteo)
%read_MeteoData Read a CSV SAM formatted text file produced by METEONORM.
%   INPUT:
%   filename: Name of the file to be read, including the whole path.
%   num_obs_meteo: Number of observations per hour in the METEONORM file.
%   Per default 1.
%
%   OUTPUT:
%   headers: Name of the variables imported from the text file.
%   meteonormData: Numerical array with the data imported from the text
%   file
%
% - F. Mendoza (June 2017)

% General
startRow = 3; % Start row (Headers row)
nVars = 14; % Number of variables included

%% Read columns of data according to the format.
fid = fopen(filename,'r');

formatSpec = ''; % Init
formatSpecH = '';
eol = '%[^\n\r]'; % End of line
for i = 1:nVars
    formatSpecH = strcat(formatSpecH,'%s');
    formatSpec = strcat(formatSpec,'%f');
end
formatSpec = strcat(formatSpec,eol);
formatSpecH = strcat(formatSpecH,eol);
delimiter = ',';

headers = textscan(fid,formatSpecH,1,'Delimiter',delimiter,'EmptyValue',NaN,...
    'HeaderLines',startRow-1,'ReturnOnError',false,'EndOfLine','\r\n');
dataArray = textscan(fid,formatSpec,8760*num_obs_meteo,'Delimiter',delimiter, 'EmptyValue',NaN,...
    'ReturnOnError',false,'EndOfLine','\r\n');

fclose(fid);

%% Output
for i = 1:length(headers)-1
    headers(i) = headers{i};
end
headers(end) = [];
meteonormData = [dataArray{1:end-1}];
