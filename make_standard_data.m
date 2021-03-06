function [out_name,out_data] = make_standard_data...
    (filedata,geodata,timedata,nodata,header,dates,GHI,DNI,DHI,others)
%MAKE_STANDARD_DATA Creates a MATLAB structure that saves the information
%required for the next modules in a standard format.
%   INPUT:
%   filedata: Info for identification and creation of the output file name
%   geodata: Geographical localization of the station
%   timedata: Info related with the time reference of the station
%   nodata: No data value
%   header: Headers of the variables included in the data matrix
%   dates: Date array of the data (same lenght of the variables data arrays)
%   GHI: Global Horizontal Irradiance data array
%   DNI: Direct Normal Irradiance data array
%   DHI: Diffuse Horizontal Irradiance data array
%   others: others variables data matrix
%
%   OUTPUT:
%   name_out: Name of the output file
%   data: Standard structure with the data
%
%   Format of the output file name: LOCAL-OWN-NN-yyyy
%   LOCAL: 5 chars of the locality
%   OWN  : 3 chars of the owner
%   NN   : 2 chars station number (same locality and owner)
%   yyyy : 4 chars year of the data (ID)
%
% - L. Ram�rez (April 2013) Initial version
% - L. Ram�rez (July 2014) Update
% - L. Ram�rez (May 2015) Update
% - F. Mendoza (February 2017) Update

%% Data structure outline
% data.filedata.own:        owner
% data.filedata.loc:        location
% data.filedata.name:       name for the output information
% data.filedata.num:        number of the station
% data.filedata.ID:         year of the data stored in the structure (identifier)
% data.geodata.lat:         latitude [�N]
% data.geodata.lon:         longitude[�E]
% data.geodata.alt:         altitude a.s.l. [m]
% data.timedata.timezone:   time reference in which data is acquired
% data.timedata.stamp:      0 ini int / 0.5 centre int / 1 end int
% data.timedata.num_obs:    number of observations per hour
% data.nodata:              no data value
% data.header:              headers of the matrix columns
%                           YYYY MM DD HH mm ss GHI DNI DHI
% data.mat:                 matrix of data

%% Structure creation

filedata.own  = string_chars(filedata.own,3,'0'); % Function
filedata.loc  = string_chars(filedata.loc,5,'0');
filedata.name = [filedata.loc '-' filedata.own '-' filedata.num '-' filedata.ID];
[filedata.num,~] = string_chars_num(filedata.num,2); % Function
filedata.ID   = string_chars(filedata.ID,4,'0');

data.filedata = filedata;
data.geodata  = geodata;
data.timedata = timedata;
data.nodata   = nodata;
data.header   = header;

matrix = double([dates GHI DNI DHI others]);
matrix(isnan(matrix(:,1)),:) = []; % Not available data is discarded
data.mat = matrix;

out_name = filedata.name;
out_data  = data;

end
