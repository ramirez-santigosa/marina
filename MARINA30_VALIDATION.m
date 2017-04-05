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
%       One Matlab file per year: dataqc i.e. 'ASP00-BOM-01-YYYY_QC'
%       Each file contains the structured variable 'dataqc'
%
% OUTPUT:
% ..\OUTPUT\3_VALIDATION
%       One Matlab file per year: dataval i.e. 'ASP00-BOM-01-YYYY_VAL'
%       Each file contains the structured variable 'dataval'
%       Same as "dataqc" but adding four fields
%  (1)  dataval.daily = Daily radiation values (Wh/m2) and the daily
%       validation process flags [# day, GHI, GHI flag, # day, DNI, DNI flag] (365X6)
%  (2)  dataval.monthly = Monthly radiation values (kWh/m2) and the monthly
%       validation process flags [# month, GHI, GHI flag, # month, DNI, DNI flag] (12X6)
%  (3)  dataval.replaced = Array with the replaced days along the years
%  (4)  dataval.nonvalid_m = Array with the number of non-valid days in 
%       each month
%
%       One Excel file with all years validation results:
%  (1)  Sheet Val_Day: Results of the daily validation of all years
%  (2)  Sheet Val_Month: Results of the monthly validation of all years
%  (3)  Sheet GHI: Summary of the monthly GHI values (kWh/m2) of each year
%  (4)  Sheet DNI: Summary of the monthly DNI values (kWh/m2) of each year
%  (5)  Sheet #_NonValid: Summary of the number of non-valid days in each
%       month and year
%  (6)  Sheet Replaced: Summary of the replaced days pointing out the
%       origin day and the replaced day
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close, clearvars, %clc
run('Configuration_BSRN_ASP.m');

if ~exist(path_val,'dir')
    mkdir(path_val);
end

% Preallocation variables for Excel export
colD = 6; res_daily_ex = zeros(365,num_years*colD);
colM = 6; res_month_ex = zeros(12,num_years*colM);
replaced_ex = zeros(num_years*12*max_nonvalid,4); idxR = 1;

% Preallocation monthly validation output tables
Table_missing = zeros(12,num_years);
Table_GHI = zeros(12,num_years);
Table_DNI = zeros(12,num_years);

for y = year_ini:year_end
    
    year_str = num2str(y);
    fprintf('Validation of %s year %s\n',name,year_str);
    
    namef = [loc '00-' owner_station '-' num];
    name_out = [namef '-' year_str];
    name_out_QC  = [name_out '_QC'];
    name_out_VAL = [name_out '_VAL'];
    
    load(strcat(path_qc,'\',name_out_QC));
    
    dataval = validation(dataqc,level,max_nonvalid); % Function Daily and Monthly validation
    save(strcat(path_val,'\',name_out_VAL),'dataval'); % Save structure
    
    % Save of validation results for Excel recording
    idx = y-year_ini;
    res_daily_ex(:,idx*colD+1:(idx+1)*colD) = dataval.daily;
    res_month_ex(:,idx*colM+1:(idx+1)*colM) = dataval.monthly;
    % Replaced days in each year
    replace = [ones(size(dataval.replaced,1),1)*y, dataval.replaced];
    replaced_ex(idxR:idxR+size(replace,1)-1,:) = replace;
    idxR = idxR+size(replace,1);
    % Non-valid days & DNI, GHI validation results
    Table_missing(:,idx+1) = dataval.nonvalid_m(:,1);
    Table_GHI(:,idx+1) = dataval.monthly(:,2);
    Table_DNI(:,idx+1) = dataval.monthly(:,5);
end

replaced_ex(idxR:end,:) = []; % Shrink

%% Headers for Excel Valiation Report

% Headers of dayly/monthly/yearly validation
headerD = cell(1,num_years*colD);
headerM = cell(1,num_years*colM);
headerY = year_ini:year_end;

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

hReplaced = {'Year','Month','Origin day','Replaced day'}; % Headers replaced days

%% Writing Validation Report in Excel

if isempty(replaced_ex)
    replaced_ex='####';
end

file_xls = strcat(path_val,'\',namef,'.xlsx');

% Switch off new excel sheet warning
warning off MATLAB:xlswrite:AddSheet

fprintf('Writing Excel file %s \n',namef);

% DAILY VALIDATION RESULTS ------------------------------------------------
% One cell per sheet (just one call of the xlswrite function per sheet)
xlswrite(file_xls,[headerD; num2cell(round(res_daily_ex))],'Val_Day','A1'); % Write the headers & results

% MONTHLY VALIDATION RESULTS ----------------------------------------------
xlswrite(file_xls,[headerM; num2cell(round(res_month_ex))],'Val_Month','A1'); % Write the headers & results

% MONTHLY GHI & DNI RESULTS AFTER VALIDATION ------------------------------
xlswrite(file_xls,[headerY; round(Table_GHI)],'GHI','A1'); % Write the headers & results

xlswrite(file_xls,[headerY; round(Table_DNI)],'DNI','A1'); % Write the headers & results

% NUMBER OF NON-VALID AND REPLACED DAYS PER MONTH AND YEAR ----------------
xlswrite(file_xls,[headerY; round(Table_missing)],'#_NonValid','A1'); % Write the headers & results

xlswrite(file_xls,[hReplaced; num2cell(replaced_ex)],'Replaced','A1'); % Write the headers & results
