%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% MODULE 3: VALIDATION AND GAP FILLING (Days and months valid)
% Version of July, 2015. L. Ramírez; At CSIRO.
% Update F. Mendoza (February 2017) at CIEMAT.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT:
% ..\OUTPUT\2_QC
%       One Matlab file per year: dataqc i.e. 'loc00-owner_station-num-YYYY_QC'
%       Each file contains the structured variable 'dataqc'
%
% OUTPUT:
% ..\OUTPUT\3_VALIDATION
%       One Matlab file per year: dataval i.e. 'loc00-owner_station-num-YYYY_VAL'
%       Each file contains the structured variable 'dataval'
%       Same as "dataqc" but adding five fields and updating 'mqc'
%       if some data is interpolated in the daily validation or if 
%       some days are substituted in the monthly validation. February 29th
%       of leap years is trimmed in 'mqc' and 'astro' matrices. Added fields:
%  (1)  dataval.interp: Saves the number of interpolated data in each day
%       for GHI and DNI. It is a cell with two matrices.
%  (2)  dataval.daily = Daily radiation values (Wh/m2) and the daily
%       validation flags [# day, GHI, GHI flag, # day, DNI, DNI flag] (365X6)
%  (3)  dataval.monthly = Monthly radiation values (kWh/m2) and the monthly
%       validation flags [# month, GHI, GHI flag, # month, DNI, DNI flag] (12X6)
%  (4)  dataval.subst = Array with the substituted days along the years
%  (5)  dataval.nonvalid_m = Array with the number of non-valid days in 
%       each month
%
%       One Excel file with all years validation results
%       'loc00-owner_station-num'_VAL
%  (1)  Sheet Interpol: Summary of the interpolated data in each day
%  (2)  Sheet Val_Day: Results of the daily validation of all years
%  (3)  Sheet Val_Month: Results of the monthly validation of all years
%  (4)  Sheet GHI: Summary of the monthly GHI values (kWh/m2) of each year
%  (5)  Sheet DNI: Summary of the monthly DNI values (kWh/m2) of each year
%  (6)  Sheet #_NonValid: Summary of the number of non-valid days in each
%       month and year
%  (7)  Sheet Substituted: Summary of the substituted days pointing out the
%       origin day and the substituted day
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close, clearvars -except cfgFile, %clc
run(cfgFile); % Run configuration file

if ~exist(path_val,'dir')
    mkdir(path_val);
end

% Preallocation variables for Excel export
colD = 6; res_daily_ex = NaN(365,num_years*colD);
colM = 6; res_month_ex = NaN(12,num_years*colM);
interpolB_ex = NaN(num_years*365,4); idxI = 1;
subst_ex = NaN(num_years*12*max_nonvalid,4); idxR = 1;

% Preallocation monthly validation output tables
Table_missing = NaN(12,num_years);
Table_GHI = NaN(12,num_years);
Table_DNI = NaN(12,num_years);
namef = [loc '00-' owner_station '-' num];

for y = year_ini:year_end
    
    year_str = num2str(y);
    fprintf('Validation of %s year %s\n',name,year_str);
    
    name_out = [namef '-' year_str];
    name_out_QC  = [name_out '_QC']; name_out_VAL = [name_out '_VAL'];
    name_in = strcat(path_qc,'\',name_out_QC,'.mat');
    if exist(name_in,'file')==2
        load(name_in); % Load of the standard data structure
    else
        warning('The file %s does not exist.\n The year %d will be skipped in the QC process.',...
            name_in,y);
        continue
    end
    
    dataval = validation(dataqc,level,max_nonvalid,max_dist); % Function Daily and Monthly validation
    save(strcat(path_val,'\',name_out_VAL),'dataval'); % Save structure
    
    % Save of validation results for Excel recording
    idx = y-year_ini;
    res_daily_ex(:,idx*colD+1:(idx+1)*colD) = dataval.daily;
    res_month_ex(:,idx*colM+1:(idx+1)*colM) = dataval.monthly;
    % Interpolated data in each year
    n_inter = size(dataval.interp{2},1);
    interpolB_ex(idxI:idxI+n_inter-1,:) = dataval.interp{2};
    idxI = idxI+n_inter;
    % Substituted days in each year
    n_sub = size(dataval.subst,1);
    subst_ex(idxR:idxR+n_sub-1,:) = dataval.subst;
    idxR = idxR+n_sub;
    % Non-valid days, GHI & DNI validation results
    Table_missing(:,idx+1) = dataval.nonvalid_m(:,1);
    Table_GHI(:,idx+1) = dataval.monthly(:,2);
    Table_DNI(:,idx+1) = dataval.monthly(:,5);
end

interpolB_ex(idxI:end,:) = []; % Shrink
subst_ex(idxR:end,:) = []; % Shrink

%% Headers for Excel Validation Report

% Headers of dayly/monthly/yearly validation
headerD = cell(1,num_years*colD);
headerM = cell(1,num_years*colM);
headerY = year_ini:year_end;
headers_m = {'Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';'Aug';'Sep';'Oct';'Nov';'Dic'}; % Headers months

for y = year_ini:year_end
    
    year_str = num2str(y);
    idx = y-year_ini;
    
    % Headers of daily validation
    headerD{1,idx*colD+1} = [year_str ' day'];
    headerD{1,idx*colD+2} = [year_str ' GHI (Wh/m2)'];
    headerD{1,idx*colD+3} = [year_str ' fdvGHI'];
    headerD{1,idx*colD+4} = [year_str ' day'];
    headerD{1,idx*colD+5} = [year_str ' DNI (Wh/m2)'];
    headerD{1,idx*colD+6} = [year_str ' fdvDNI'];
    
    % Header of monthly validation
    headerM{1,idx*colM+1} = [year_str ' month'];
    headerM{1,idx*colM+2} = [year_str ' GHI (kWh/m2)'];
    headerM{1,idx*colM+3} = [year_str ' fmvGHI'];
    headerM{1,idx*colM+4} = [year_str ' month'];
    headerM{1,idx*colM+5} = [year_str ' DNI (kWh/m2)'];
    headerM{1,idx*colM+6} = [year_str ' fmvDNI'];
    
end

headerD = ['Month', headerD];
% Month for daily results
year_m = zeros(365,1); k = 1; % No leap years
for month = 1:12
    for d = 1:num_days_m(month)
        year_m(k) = month;
        k = k+1;
    end
end

hInterpB = {'Year','Month','Day','# data interpolated'}; % Headers interpolated days
hSubst = {'Year','Month','Origin day','Substituted day'}; % Headers substituted days

%% Writing Validation Report in Excel

if isempty(interpolB_ex)
    interpolB_ex = '####';
end
if isempty(subst_ex)
    subst_ex = '####';
end

file_xls = strcat(path_val,'\',namef,'_VAL','.xlsx');

% Switch off new excel sheet warning
warning off MATLAB:xlswrite:AddSheet

fprintf('Writing Excel file %s \n',file_xls);

% INTERPOLATED DAYS PER MONTH AND YEAR ------------------------------------
% One cell per sheet (just one call of the xlswrite function per sheet)
xlswrite(file_xls,[hInterpB; num2cell(interpolB_ex)],'Interpol','A1'); % Write the headers & results

% DAILY VALIDATION RESULTS ------------------------------------------------
xlswrite(file_xls,[headerD; num2cell([year_m round(res_daily_ex)])],'Val_Day','A1'); % Write the headers & results

% MONTHLY VALIDATION RESULTS ----------------------------------------------
xlswrite(file_xls,[headerM; num2cell(round(res_month_ex))],'Val_Month','A1'); % Write the headers & results

% MONTHLY GHI & DNI RESULTS AFTER VALIDATION ------------------------------
ghi_ex = [['Month' num2cell(headerY)]; [headers_m, num2cell(round(Table_GHI))]];
xlswrite(file_xls,ghi_ex,'GHI','A1'); % Write the headers & results

dni_ex = [['Month' num2cell(headerY)]; [headers_m, num2cell(round(Table_DNI))]];
xlswrite(file_xls,dni_ex,'DNI','A1'); % Write the headers & results

% NUMBER OF NON-VALID AND SUBSTITUTED DAYS PER MONTH AND YEAR ----------------
nov_ex = [['Month' num2cell(headerY)]; [headers_m, num2cell(round(Table_missing))]];
xlswrite(file_xls,nov_ex,'#_NonValid','A1'); % Write the headers & results

xlswrite(file_xls,[hSubst; num2cell(subst_ex)],'Substituted','A1'); % Write the headers & results
