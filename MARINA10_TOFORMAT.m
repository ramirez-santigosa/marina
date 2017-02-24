%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% MODULE 1: TOFORMAT
% Version of July, 2015. L. Ramírez; At CSIRO.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT:
%  ..\DATA\(ANNUAL DIRECTORIES PER YEAR)
%           monthly files form BSRN (1995-2014)
%           (i.e.:'ASP_1995-01_0100.txt')
%
% OUTPUTS:
% ..\OUTPUTS\1_FORMAT\
% (1)   One Matlab file per year: data  'ASP00-BOM-01-1995'
%       Each file contains the structured variable 'data'
% (2)   One Matlab file per year        'Summary1995'
%           aaaa mmm GHI DNI DHI
%           Values: -1 no file; 0 wrong file; column number in INPUT file

%% Data structure outline
% data.filedata.own:        owner
% data.filedata.loc:        location
% data.filedata.name:       name for the output information
% data.filedata.num:        number of the station
% data.filedata.ID:         year of the data stored in the structure (identifier)
% data.geodata.lat:         latitude [ºN]
% data.geodata.lon:         longitude[ºE]
% data.geodata.alt:         altitude a.s.l. [m]
% data.timedata.timezone:   time reference in which data is acquired
% data.timedata.stamp:      0 ini int / 0.5 centre int / 1 end int
% data.timedata.num_obs:    number of observations per hour
% data.nodata:              no data value
% data.header:              headers of the matrix columns
%                           YYYY MM DD HH mm ss GHI DNI DHI
% data.mat:                 matrix of data

%% Data assignment

%! num_years = year_end-year_ini+1;
filedata.own = owner_station;
filedata.loc = loc;
filedata.name = name;
filedata.num = num;
% geodata is read from data file (lat, lon, alt)
timedata.timezone = ref_temp; % Time reference in which data is acquired
timedata.stamp = time_stamp;
timedata.num_obs = num_obs;
nodata = no_data;
header = {'YYYY', 'MM', 'DD', 'HH', 'mm', 'ss', 'GHI', 'DNI', 'DHI'};

%% Loop through years

for y = year_ini:year_end
    
    year_str = num2str(y);
    fprintf('Treatment of %s year %s\n',name,year_str);
    filedata.ID = year_str;
    
    [name_out,data] = Year_BSRN_to_format(path_in,path_format,num_obs,filedata,timedata,nodata,header,y);
    save(strcat(path_format,'\',name_out),'data'); % Save the standard format structure
    
end
