function [ok,ID, geo, dates, data, col]=read_BSRN_LR0100(filename)
% 
% This funciton reads the monthly files containing the BSRN LR0100
%
%   INPUT: filename with the whole path.
%   OUTPUT: ok      (1=ok; 0= no ok)
%           ID      (station BSRN ID)
%           geo     (geo.lat latitude decimal degree)
%                   (geo.lon longitude decimal degree)
%           	    (geo.alt height meters)
%           dates   (a numerical vector with the data dates)
%           data    (a numerical matrix with the data)
%           col     (col.GHI GHI column) 
%                   (col.DHI DHI column) 
%                   (col.DNI DHI column) 
%                   (col.LWD LWD column) 
% USE:
% [ok, ID, geo, dates, data, col]=read_BSRN_LR0100(filename);
%
% Lourdes Ramírez May 2015
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Abre un archivo ASCII delimitado por tabuladores con 1 líneas de cabecera 
% my_data.textdata = header and text data (station and date)
% my_data.data     = matrix with numerical data

my_data = importdata (filename,'\t', 1 ) ; 

%check if textdata and data exist
hay_datos = isfield(my_data, 'data');
hay_texto = isfield(my_data, 'textdata');

if (hay_datos==1 || hay_texto==1) %if both fields exist

    ok=1;
    num_cols = length(my_data.textdata(1,:));

    %---------------------------------------------------------
    % WORKING WITH my_data.textdata
    % output: ID (station)
    %         dates (vector with the date values in numeric format)
    %         col   (struct with the column numbers of radiation variables)
    %---------------------------------------------------------

    % First column => station ID 
    % (All rows have the same value, only 1 is needed)
    ID = my_data.textdata(2,1);

    % Second column => dates vector
    % (the whole vector is needed, not the header)
    Date = my_data.textdata(2:end,2);
    % (convert info character matrix)
    Date_mat = char(Date);
    % (assign the position for each date variable)
    aaaa = Date_mat(:,1:4);
    mm = Date_mat(:,6:7);
    dd = Date_mat(:,9:10);
    hh = Date_mat(:,12:13);
    mi = Date_mat(:,15:16);

    anno = str2num(aaaa);
    mes  = str2num(mm);
    dia  = str2num(dd);
    hora = str2num(hh);
    min  = str2num(mi);

    dates=datenum(anno,mes,dia,hora,min,0);

    % Data headers
    % 1:id; 2:date; 3:Lat; 4:Lon; 5:Hei;

    for i=6:num_cols
        data_headers{i-5,1} = my_data.textdata(1,i);
    end
    % data_headers=data_headers';

    % Finding the columns of each variable
    col.GHI = NaN;
    col.DHI = NaN;
    col.DNI = NaN;
    col.LWD = NaN;

    for i=1:length(data_headers(:,1))
        temp=char(data_headers{i,1}(1,:));
        es_GHI = strfind(temp, '(GLOBAL) radiation [W/m**2]');
        if es_GHI>0 col.GHI = i; end
        es_DHI = strfind(temp, 'Diffuse radiation [W/m**2]');
        if es_DHI>0 col.DHI = i; end
        es_DNI = strfind(temp, 'Direct radiation [W/m**2]');
        if es_DNI>0 col.DNI = i; end
        es_LWD = strfind(temp, 'Long-wave downward radiation [W/m**2]');
        if es_LWD>0 col.LWD = i; end
    end

    %---------------------------------------------------------
    % WORKING WITH my_data.data
    % output: geo.Lat   (latitude)
    %         geo.Lon   (longitude)
    %         geo.Hei   (height)
    %         data  (matrix of output data)
    %---------------------------------------------------------

    geo.lat = my_data.data(1,1);
    geo.lon = my_data.data(1,2);
    geo.alt = my_data.data(1,3);

    data= my_data.data(:,4:end);   

else % if one of the fields does not exist
    
    ok  = 0;
    ID  = NaN;
    geo = NaN;
    dates = NaN;
    data  = NaN;
    col   = NaN;
    
end
