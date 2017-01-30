function [ok,ID, geo, dates, data, col]=read_SEVILLA(filename)
% 
% This funciton reads annual files 
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
% Lourdes Ramírez July 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


[datos,texto]=xlsread(filename);


num_cols = length(my_data.textdata(1,:));


ID = 1;


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


    geo.lat = my_data.data(1,1);
    geo.lon = my_data.data(1,2);
    geo.alt = my_data.data(1,3);

    data= my_data.data(:,4:end);   

   
    ok  = 0;
    ID  = NaN;
    geo = NaN;
    dates = NaN;
    data  = NaN;
    col   = NaN;
    
end
