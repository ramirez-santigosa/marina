%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% MODULE 1: TOFORMAT
% Version of July, 2015. L. Ramírez; At CSIRO.
% Update F. Mendoza (June 2017) at CIEMAT.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT:
% ..\INPUT\(Directory or file structure according to the input format)
%
% OUTPUT:
% ..\OUTPUT\1_FORMAT\
% (1)   One Matlab file per year i.e. 'loc00-owner_station-num-YYYY'
%       Each file contains the structured variable 'data'
% (2)   One Matlab file per year i.e. 'SummaryYYYY'
%       GHI DNI DHI
%       Values: -1 no data; 0 wrong data; column number in the input file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
%                           YYYY MM DD HH mm ss GHI DNI DHI others
% data.mat:                 matrix of data

close, clearvars -except cfgFile, %clc
run(cfgFile); % Run configuration file

%% Data assignment

filedata.own = owner_station;
filedata.loc = loc;
filedata.name = name;
filedata.num = num;
% geodata is read from data files (lat, lon, alt)
timedata.timezone = ref_temp; % Time reference in which data is acquired
timedata.stamp = time_stamp;
timedata.num_obs = num_obs;
nodata = no_data;

%% Loop through years

for y = year_ini:year_end
    
    year_str = num2str(y);
    fprintf('Treatment of %s year %s\n',name,year_str);
    filedata.ID = year_str;
    
    switch inputFormat
        case 'BSRN'
            [name_out,data] = Year_BSRN_to_format(path_in,path_format,num_obs,filedata,timedata,nodata,header,y);
        case 'MESOR'
            [name_out,data] = Year_MESOR_to_format(path_in,path_format,filedata,timedata,nodata,header,y);
        otherwise
            warning('Not valid input format.');
            break
    end
    
    if ~isempty(data)
        save(strcat(path_format,'\',name_out),'data'); % Save the standard format structure
    end
    
end
