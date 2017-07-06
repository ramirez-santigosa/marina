function [ok,geo,dates,data,col] = read_MESOR_v1_1(filename)
%READ_MESOR_v1_1 Reads the annual MESOR v1.1 11.2007 files
%   INPUT:
%   filename: Name of the file with the whole path.
%
%   OUTPUT:
%   ok: ok = 1, not ok = 0
%   geo: Structure
%        geo.lat latitude (decimal degree)
%        geo.lon longitude (decimal degree)
%        geo.alt altitude (meters)
%   dates: a datetime array with the data dates
%   data: a numerical matrix with the data
%   variables: Cell array with the variables include in this file
%   col: Structure
%        col.GHI: GHI column position
%        col.DNI: DNI column position
%        col.DHI: DHI column position
%        col.t_air: Air temperature column position
%        col.rh: Relative humidity column position
%        col.bp: Air pressure column position
%        col.ws: Wind speed column position
%
% - F. Mendoza (June 2017) Update

%% Reading of the headers to extract initial info
fid = fopen(filename,'r'); % Open file
go = true; % Stop condition
hl = 0; % Number of header lines
nVars = 0; % Number of measured variables (channels)
variables = cell(1,21); % Pre-allocate cell to save the variables included
% units = cell(1,21); % Pre-allocate cell to save the units of the variables
tline = 'abc'; % Initialized to avoid a possible infinite loop

while go && ischar(tline) % Read line by line until #begindata
    hl = hl+1; % Update
    tline = fgetl(fid); % Get the header line
    tline = strtrim(tline); % Trim whitespaces
    if isempty(tline)
        continue
    end
    C = textscan(tline,'%s'); % Break into strings between spaces or tabs
    header = C{1,1}{1,1}; % First position on the cell is the actual header
    
    switch header % Evaluate the header
        case '#channel' % Variable
            nVars = nVars+1; % Update
            variables(1,nVars) = C{1,1}(2,1);
%             units(1,nVars) = C{1,1}(3,1);
        case '#location.latitude[degN]:'
            geo.lat = str2double(C{1,1}{2,1}); % Latitude
        case '#location.longitude[degE]:'
            geo.lon = str2double(C{1,1}{2,1}); % Longitude
        case '#location.altitude[m]:'
            geo.alt = str2double(C{1,1}{2,1}); % Altitude
%         case '#timezone'
%             tz = C{1,1}{2,1};
        case '#begindata'
            go = false;
    end
end
fclose(fid); % Close file
variables = variables(1,3:nVars); % Trim variables (First two columns always date and time)
% units = units(1,3:nVars);
nVars = nVars-2;

%% Finding the columns of each variable (GHI DNI DHI t_air rh bp ws)
col.GHI = -1; col.DNI = -1; col.DHI = -1;
col.t_air = -1; col.rh = -1; col.bp = -1; col.ws = -1;

for i = 1:nVars
    temp = char(variables{1,i});
    
    switch temp
        case 'GHI'
            col.GHI = i; continue
        case 'DNI'
            col.DNI = i; continue
        case 'DHI'
            col.DHI = i; continue
        case 't_air'
            col.t_air = i; continue
        case 'rh'
            col.rh = i; continue
        case 'bp'
            col.bp = i; continue
        case 'ws'
            col.ws = i; continue
    end
end

%% Read columns of data according to the format.
fid = fopen(filename,'r'); % Open file

formatSpec = '%{yyyy-MM-dd HH:mm}D'; % Date and Time
eol = '%[^\n\r]'; % End of line
for i = 1:nVars
    formatSpec = strcat(formatSpec,'%f');
end
formatSpec = strcat(formatSpec,eol);
delimiter = '\t';

try
    dataArray = textscan(fid,formatSpec,'Delimiter',delimiter,'EmptyValue',NaN,...
        'HeaderLines',hl,'ReturnOnError',false,'EndOfLine','\r\n');
catch
    warning('There is a problem reading the file %s',filename);
    ok = 0;
    geo = NaN;
    dates = NaN;
    data = NaN;
    col = NaN;
    return
end
fclose(fid); % Close file
ok = 1; % Reading complete!

%% Output
dates = dataArray{1,1};
dates = rmmissing(dates); % Trim last one (#enddata)
data = cell2mat(dataArray(1,2:end-1));

end
