function [name_out,data] = Year_BSRN_to_format...
    (path_in,path_out,num_obs,filedata,timedata,nodata,header,year)
%YEAR_BSRN_TO_FORMAT Summary of this function goes here
%   INPUT:
%   path_in: Path of the input files
%   path_out: Path of the folder where standard structures will be saved
%   num_obs: Number of observations per hour
%   filedata: Info for identificaction and creation of the output file name
%   timedata: Info related with the time reference of the data
%   nodata: No data value
%   header: Headers of the variables included in the data matrix
%   year: Year of the data (ID)
%
%   OUTPUT:
%   name_out: Name of the output file
%   data: Standard structure with the data

%% Output file per year

num_var = 3; % Number of variables considered GHI DNI DHI
date_year = zeros(num_obs*8760,6); % Preallocate
data_year = zeros(num_obs*8760,num_var); % Preallocate

yyyy = num2str(year);
row_summary = 1; % Init summary row
sum_date = zeros(12,2); % Preallocate
sum_col = zeros(12,num_var); % Preallocate
idx = 1;

for month = 1:12
    %! clear datos_mes fechas_vec
    
    %saving a summary of the months
    sum_date(row_summary,:) = [year month];
    
    mm = num2str(month);
    if length(mm)<2 % Month => two characters
        mm = strcat('0',mm);
    end
    
    filename = strcat(filedata.loc,'_',yyyy,'-',mm,'_0100.txt');
    disp(['Reading file: ' filename]);
    % Name of the file with path
    file_id = strcat(path_in,'\',yyyy,'\',filename);
    
    % Test if file exist
    fid = fopen(file_id);
    if fid > -1  % exists the file
        fclose(fid);
        [ok, ~, geo, dates, info, col] = read_BSRN_LR0100(file_id);
        
        if ok == 1 % exist and the inner information is ok
            dates_vec = datevec(dates);
            %! fechas = dates_vec(:,1:5);
            
            %saving a summary of the variables order
            sum_col(row_summary,1) = col.GHI;
            sum_col(row_summary,2) = col.DNI;
            sum_col(row_summary,3) = col.DHI;
            
            data_month = NaN(length(info),num_var); % Init data month
            %saving the data
            if ~isnan(col.GHI)
                data_month(:,1) = info(:,col.GHI);
            end
            
            if ~isnan(col.DNI)
                data_month(:,2) = info(:,col.DNI);
            end
            
            if ~isnan(col.DHI)
                data_month(:,3) = info(:,col.DHI);
            end
            
            geodata.lat = geo.lat;
            geodata.lon = geo.lon;
            geodata.alt = geo.alt;
            
            %ADD THE MONTHLY DATA AND DATE TO THE PREVIOUS ONES
            date_year(idx:idx+length(dates_vec)-1,:) = dates_vec;
            data_year(idx:idx+length(data_month)-1,:) = data_month;
            idx = idx+length(data_month); % Update index
        else %exist BUT the inside information is NOT ok
            sum_col(row_summary,:) = zeros(1,num_var);
            disp(['File ', file_id, ' exists, but inside information is not ok.']);
        end
        
    else % the file DOES NOT exists
        %saving a summary when file does not exist
        sum_col(row_summary,:) = -1*ones(1,num_var);
        disp(['File ', file_id, ' does not exists.'])
    end
    
    row_summary = row_summary+1; % summary row
    
end

date_year(idx:end,:) = []; % Shrink variables
data_year(idx:end,:) = [];

%% Plot figure

path_fig = strcat(path_out,'\','figures');
if ~exist(path_fig,'dir')
    mkdir(path_fig);
end

plot(sum_col,'*');
axis([0 12 -2 max(max(sum_col))+1]);
title([' Summary ' yyyy],'Fontsize',16);
xlabel('Months','Fontsize',16);
ylabel('Num. column in input file','Fontsize',16);
hleg=legend('GHI','DNI','DHI');
% set(hleg,'Location','WestOutside');
set(hleg,'Location','SouthEastOutside');
set(hleg,'Fontsize',16);
grid on;
% saveas(gcf,strcat(ruta_out,'\','Summary',aaaa),'png');
print('-djpeg','-opengl','-r350',strcat(path_fig,'\','Summary',yyyy))

%% Make a structure for each year

[name_out,data]=...
    make_standard_data(filedata,geodata,timedata,nodata,header,...
    date_year,data_year(:,1),data_year(:,2),data_year(:,3),[]);% Function

% Save the summary of dates and column position of the variables
% aaaa mmm GHI DNI DHI (column position)
% Values: -1 no file; 0 wrong file; column number in original file
save(strcat(path_out,'\','Summary',yyyy),'sum_date','sum_col');

end
