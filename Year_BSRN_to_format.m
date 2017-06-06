function [name_out,data] = Year_BSRN_to_format...
    (path_in,path_out,num_obs,filedata,timedata,nodata,header,year)
%YEAR_BSRN_TO_FORMAT Reads the BSRN input files and saves a standard format
%structure.
%   INPUT:
%   path_in: Path of the input files. BSRN data usually comes structured in
%   folders
%   ..\path_in\(ANNUAL DIRECTORIES PER YEAR)
%       monthly files from BSRN (i.e.: 'ASP_1995-01_0100.txt',
%       'ASP_1995-02_0100.txt'...)
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
% - F. Mendoza (February 2017) Update

%% Output file per year

num_var = 3; % Number of variables considered (GHI DNI DHI)
date_year = zeros(num_obs*8784,6); % Pre-allocate (considered leap years)
data_year = zeros(num_obs*8784,num_var); % Pre-allocate (considered leap years)

yyyy = num2str(year);
row_summary = 1; % Init summary row
sum_date = zeros(12,2); % Pre-allocate
sum_col = zeros(12,num_var); % Pre-allocate
idx = 1;

for m = 1:12
    % Saving a summary of the months
    sum_date(row_summary,:) = [year m];
    
    mm = num2str(m);
    if length(mm)<2 % Month => two characters
        mm = strcat('0',mm);
    end
    
    filename = strcat(filedata.loc,'_',yyyy,'-',mm,'_0100.txt');
    disp(['Reading file: ' filename]);
    file_id = strcat(path_in,'\',yyyy,'\',filename); % Name of the file with path
    
    % Test if file exist
    fid = fopen(file_id);
    if fid > -1  % Exists the file
        fclose(fid);
        [ok, ~, geo, dates, info, col] = read_BSRN_LR0100(file_id); % Function
        info(isnan(info)) = nodata; % Assign no data value. Per default in the import process unimportable cells are replaced with NaN
        
        if ok == 1 % Exist and the inner information is ok
            dates_vec = datevec(dates);
            
            % Saving a summary of the variables order
            sum_col(row_summary,1) = col.GHI;
            sum_col(row_summary,2) = col.DNI;
            sum_col(row_summary,3) = col.DHI;
            
            data_month = nodata*ones(length(info),num_var); % Init data month
            % Saving the data
            if ~isnan(col.GHI)
                data_month(:,1) = info(:,col.GHI);
            end
            
            if ~isnan(col.DNI)
                data_month(:,2) = info(:,col.DNI);
            end
            
            if ~isnan(col.DHI)
                data_month(:,3) = info(:,col.DHI);
            end
            % Saves geographical info
            geodata.lat = geo.lat;
            geodata.lon = geo.lon;
            geodata.alt = geo.alt;
            
            % Add the monthly data and date to the previous ones
            date_year(idx:idx+size(dates_vec,1)-1,:) = dates_vec;
            data_year(idx:idx+size(data_month,1)-1,:) = data_month;
            idx = idx+size(data_month,1); % Update index
            
        else % Exist BUT the inside information is NOT ok
            sum_col(row_summary,:) = zeros(1,num_var);
            warning(['File ', file_id, ' exists, but inside information is not ok.']);
        end
        
    else % File DOES NOT exists
        % Saving a summary when file does not exist
        sum_col(row_summary,:) = -1*ones(1,num_var);
        warning(['The file ', file_id, ' does not exist.'])
    end
    
    row_summary = row_summary+1; % Summary row
    
end

date_year(idx:end,:) = []; % Shrink variables
data_year(idx:end,:) = [];

%% Plot summary figure

path_fig = strcat(path_out,'\','figures');
if ~exist(path_fig,'dir')
    mkdir(path_fig);
end

plot(sum_col,'*');
axis([0 12 -2 max(max(sum_col))+1]);
title([' Summary ' yyyy],'Fontsize',16);
xlabel('Months','Fontsize',16);
ylabel('Num. column in input file','Fontsize',16);
hleg = legend('GHI','DNI','DHI');
% set(hleg,'Location','WestOutside');
set(hleg,'Location','SouthEastOutside');
set(hleg,'Fontsize',16);
grid on;
% saveas(gcf,strcat(ruta_out,'\','Summary',aaaa),'png');
print('-djpeg','-opengl','-r350',strcat(path_fig,'\','Summary',yyyy))

%% Make a structure for each year

[name_out,data]=...
    make_standard_data(filedata,geodata,timedata,nodata,header,...
    date_year,data_year(:,1),data_year(:,2),data_year(:,3),[]); % Function

% Save the summary of dates and column position of the variables
% aaaa mmm GHI DNI DHI (column position)
% Values: -1 no file; 0 wrong file; column number in original file
save(strcat(path_out,'\','Summary',yyyy),'sum_date','sum_col');

end
