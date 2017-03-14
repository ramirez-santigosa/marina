function [ok,ID,geo,dates,data,col] = read_BSRN_LR0100(filename)
%READ_BSRN_LR0100 Reads the monthly files containing the BSRN LR0100
%   INPUT:
%   filename: Name of the file with the whole path.
%
%   OUTPUT:
%   ok: ok = 1, not ok = 0
%   ID: BSRN station ID
%   geo: Structure
%        geo.lat latitude (decimal degree)
%        geo.lon longitude (decimal degree)
%        geo.alt altitude (meters)
%   dates: a numerical vector with the data dates
%   data: a numerical matrix with the data
%   col: Structure
%        col.GHI: GHI column position
%        col.DHI: DHI column position
%        col.DNI: DHI column position
%        col.LWD: LWD column position
%
% - L. Ramírez (May 2015)
% - F. Mendoza (February 2017) Update

% Open an ASCII file delimited by tabs with 1 headers line
my_data = importdata(filename,'\t', 1);
% my_data.textdata = header and text data (station and date)
% my_data.data     = matrix with numerical data

% Check if textdata and data exist
is_data = isfield(my_data, 'data');
is_text = isfield(my_data, 'textdata');

if (is_data==1 || is_text==1) % If both fields exist
    
    ok = 1;
    num_cols = length(my_data.textdata(1,:));
    
    %----------------------------------------------------------------------
    % WORKING WITH my_data.textdata
    % output: ID (station)
    %         dates (vector with the date values in numeric format)
    %         col   (struct with the column numbers of radiation variables)
    %----------------------------------------------------------------------
    
    % First column => station ID (All rows have the same value, only 1 is needed)
    ID = my_data.textdata(2,1);
    % Second column => dates vector (the whole vector is needed, not the header)
    Date = my_data.textdata(2:end,2);
    % Convert into character matrix
    Date_mat = char(Date);
    % Assign the position for each date variable
    yyyy = Date_mat(:,1:4);
    mm = Date_mat(:,6:7);
    dd = Date_mat(:,9:10);
    hh = Date_mat(:,12:13);
    mi = Date_mat(:,15:16);
    
%     year = zeros(length(yyyy),1); % a = cellstr(yyyy);
%     month = zeros(length(mm),1);
%     day = zeros(length(dd),1);
%     hour = zeros(length(hh),1);
%     min = zeros(length(mi),1);
% 
%     for i = 1:length(yyyy)
%         year(i) = str2double(yyyy(i,:));
%         month(i) = str2double(mm(i,:));
%         day(i) = str2double(dd(i,:));
%         hour(i) = str2double(hh(i,:));
%         min(i) = str2double(mi(i,:));
%     end
    
    year = str2num(yyyy); % year = str2double(a);
    month = str2num(mm);
    day = str2num(dd);
    hour = str2num(hh);
    min = str2num(mi);
    
    dates = datenum(year,month,day,hour,min,0);
    
    % Data headers
    % 1:ID; 2:Date; 3:Lat; 4:Lon; 5:Hei;
    data_headers = cell(num_cols-5,1); % Preallocate cell
    for i = 6:num_cols
        data_headers{i-5,1} = my_data.textdata(1,i);
    end
    
    % Finding the columns of each variable
    col.GHI = NaN;
    col.DHI = NaN;
    col.DNI = NaN;
    col.LWD = NaN;
    
    for i = 1:length(data_headers(:,1))
        temp = char(data_headers{i,1});
        
        is_GHI = strfind(temp, '(GLOBAL) radiation [W/m**2]');
        if is_GHI>0
            col.GHI = i;
        end
        
        is_DHI = strfind(temp, 'Diffuse radiation [W/m**2]');
        if is_DHI>0
            col.DHI = i;
        end
        
        is_DNI = strfind(temp, 'Direct radiation [W/m**2]');
        if is_DNI>0
            col.DNI = i;
        end
        
        is_LWD = strfind(temp, 'Long-wave downward radiation [W/m**2]');
        if is_LWD>0
            col.LWD = i;
        end
    end
    
    %----------------------------------------------------------------------
    % WORKING WITH my_data.data
    % output: geo.lat   (latitude)
    %         geo.lon   (longitude)
    %         geo.alt   (altitude)
    %         data      (matrix of output data)
    %----------------------------------------------------------------------
    
    geo.lat = my_data.data(1,1); % Latitude
    geo.lon = my_data.data(1,2); % Longitude
    geo.alt = my_data.data(1,3); % Altitude
    
    data = my_data.data(:,4:end); % Data
    
else % If one of the fields does not exist
    
    ok = 0;
    ID = NaN;
    geo = NaN;
    dates = NaN;
    data = NaN;
    col = NaN;
    
end
end
