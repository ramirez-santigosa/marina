function [name_out,data] = Year_MESOR_to_format...
    (path_in,path_out,filedata,timedata,nodata,header,year)
%YEAR_MESOR_TO_FORMAT Reads the MESOR input files and saves a standard format
%structure.
%   INPUT:
%   path_in: Path of the input files. MESOR data usually comes in annual
%   files
%   ..\path_in\(ANNUAL FILES PER YEAR) (i.e.: 'PSA_Mesor_2002.txt', 
%   'PSA_Mesor_2003.txt'...)
%   path_out: Path of the folder where standard structures will be saved
%   num_obs: Number of observations per hour
%   filedata: Info for identification and creation of the output file name
%   timedata: Info related with the time reference of the station
%   nodata: No data value
%   header: Headers of the variables included in the data matrix
%   year: Year of the data (ID)
%
%   OUTPUT:
%   name_out: Name of the output file
%   data: Standard structure with the data
%
% - F. Mendoza (June 2017) Update

%% Output file per year

num_var = 7; % Number of variables considered (GHI DNI DHI t_air rh bp ws)
yyyy = num2str(year); % Number of the year (string)

filename = strcat(filedata.loc,'_','Mesor','_',yyyy,'.txt');
disp(['Reading file: ' filename]);
file_id = strcat(path_in,'\',filename); % Name of the file with path

% Test if file exist
fid = fopen(file_id,'r');
if fid > -1  % Exists the file
    fclose(fid);
    [ok,geo,dates,info,col] = read_MESOR_v1_1(file_id); % Function
    info(isnan(info)) = nodata; % Assign no data value. Per default in the import process unimportable cells are replaced with NaN
    info(info==-9999) = nodata; % Assign no data value. In the MESOR format -9999 was used to represent infinite or missing measurements

    if ok==1 % Exist and the inner information is ok
        date_year = datevec(dates);

        % Saving a summary of the variables order
        sum_col = [col.GHI col.DNI col.DHI col.t_air col.rh col.bp col.ws]; % Standard order
        colsVar = sum_col(sum_col~=-1); % Variables included
        data_year = info(:,colsVar); % Data that will be saved
        
        % Saves geographical info
        geodata.lat = geo.lat;
        geodata.lon = geo.lon;
        geodata.alt = geo.alt;

    else % Exist BUT the inside information is NOT ok
        sum_col = zeros(1,num_var);
        warning(['File ', file_id, ' exists, but inside information is not ok.']);
    end

else % File DOES NOT exists
    warning(['The file ', file_id, ' does not exist.'])
    name_out = ' ';
    data = [];
    return
end

%% Plot summary figure
path_fig = strcat(path_out,'\','figures');
if ~exist(path_fig,'dir')
    mkdir(path_fig);
end

plot(sum_col,'*');
axis([1 length(sum_col) -2 max(sum_col)+1]);
title(['Summary ' yyyy],'Fontsize',16);
xlabel('Variables','Fontsize',16);
ylabel('Num. column in input file','Fontsize',16);
xticklabels({'GHI','DNI','DHI','t air','rh','bp','ws'});
grid on;
print('-djpeg','-opengl','-r350',strcat(path_fig,'\','Summary',yyyy))

%% Make a structure for each year
colsHeader = sum_col~=-1;
colsHeader = [true(1,6) colsHeader]; % First 6 columns YYYY... ss
header = header(1,colsHeader); % Headers of the variables that will be saved
colsOthers = sum_col(4:end);
colsOthers = colsOthers(colsOthers~=-1); % Columns of the other meteorological variables

[name_out,data]=...
    make_standard_data(filedata,geodata,timedata,nodata,header,...
    date_year,data_year(:,col.GHI),data_year(:,col.DNI),data_year(:,col.DHI),data_year(:,colsOthers)); % Function

% Save the summary of dates and column position of the variables
% aaaa mmm GHI DNI DHI (column position)
% Values: -1 no file; 0 wrong file; column number in original file
save(strcat(path_out,'\','Summary',yyyy),'sum_col');

end
