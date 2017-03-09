%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% MODULE 3: VALIDATION (Days and months valids)
% Version of July, 2015. L. Ramírez; At CSIRO.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT:
% ..\OUTPUT\2_QC
%       One Matlab file per year: dataqc  'ASP00-BOM-01-YYYY_QC'
%       Each file contains the structured variable  'dataqc'
%       Same as "data" but adding two more variables
%       (records are sorted and a the year is full)
%  (1)  data.mqc  = [date_vec(:,1:6)(TST) GHIord eGHI DNIord eDNI DHIord eDHI];
%  (2)  datos.astro = [dj e0 ang_day et tst_hours w dec cosz i0 m];
%
% OUTPUT: !!!
% ..\OUTPUT\3_VALIDATION
% (1)   One Matlab file per year: dataval 'ASP00-BOM-01-YYYY_VAL' 
%       Each file contains the structured variable   'datosc'
%       Same as "datosc" but adding four more variables,
%      (1) diarios      365 X 6 columns by year (DAY   GHI VAL DAY   DNI VAL)
%      (2) mensuales    12  X 6 columns by year (month GHI VAL month DNI VAL)
%      (3) cambios      description of the changes of the year
%      (4) cambios_mes  number of not valid or changed days by month
% (2)   output EXCEL file:
%              sheet Val-dia
%              sheet Val-mes
%              sheet Tabla-GHI
%              sheet Tabla-DNI
%              sheet Tabla-FALTAN
%              sheet cambiados
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close, clearvars, %clc
run('Configuration_BSRN_ASP.m');

if ~exist(path_val,'dir')
    [s,mess,messid] = mkdir(path_val);
end

max_nonvalid = 4; % Maximum number of allowed non valid days in a month
% Preallocation variables for Excel export
colD = 6; res_daily_ex = zeros(365,(year_end-year_ini+1)*colD);
colM = 6; res_month_ex = zeros(12,(year_end-year_ini+1)*colM);
replaced_ex = zeros((year_end-year_ini+1)*12*max_nonvalid,4); idxR = 1;

% Preallocation monthly validation output tables
Table_missing = zeros(12,year_end-year_ini+1);
Table_GHI = zeros(12,year_end-year_ini+1);
Table_DNI = zeros(12,year_end-year_ini+1);

% Level for validation. Defines since which flag value a day is valid according to the QC flags
level = 1;

for y = year_ini:year_end
    
    year_str = num2str(y);
    fprintf('Validation of %s year %s\n',name,year_str); 
    changes_year = [];
    
    namef = [loc '00-' owner_station '-' num];
    name_out = [namef '-' year_str];
    name_out_QC  = [name_out '_QC'];
    name_out_VAL = [name_out '_VAL'];

    load(strcat(path_qc,'\',name_out_QC));
    
    dataval = validation(dataqc,level,max_nonvalid); % Daily and Monthly validation
    save(strcat(path_val,'\',name_out_VAL),'dataval'); % Save structure
    
    % Save of validation results for Excel recording
    idx = y-year_ini;
    res_daily_ex(:,idx*colD+1:(idx+1)*colD) = dataval.daily;
    res_month_ex(:,idx*colM+1:(idx+1)*colM) = dataval.monthly;

    replace = [ones(size(dataval.replaced,1),1)*y, dataval.replaced];
    replaced_ex(idxR:idxR+size(replace,1)-1,:) = replace;
    idxR = idxR+length(replace);
    
    Table_missing(:,idx+1) = dataval.replaced_month(:,1);
    Table_GHI(:,idx+1) = dataval.monthly(:,2);
    Table_DNI(:,idx+1) = dataval.monthly(:,5);
end

replaced_ex(idxR:end,:) = []; % Shrink

%% Headers for Excel Valiation Report

% Headers of dayly/monthly/yearly validation
headerD = cell(1,(year_end-year_ini+1)*colD);
headerM = cell(1,(year_end-year_ini+1)*colM);
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

% Switch off warning of new excel sheet.
warning off MATLAB:xlswrite:AddSheet

fprintf('Writing Excel file %s \n',namef);

% DAILY VALIDATION RESULTS ------------------------------------------------
xlswrite(file_xls,headerD,'Val_Day','A1'); % Write the headers
xlswrite(file_xls,round(res_daily_ex),'Val_Day','A2'); % Write the results

% MONTHLY VALIDATION RESULTS ----------------------------------------------
xlswrite(file_xls,headerM,'Val_Month','A1'); % Write the headers
xlswrite(file_xls,round(res_month_ex),'Val_Month','A2'); % Write the results

% MONTHLY GHI & DNI RESULTS AFTER VALIDATION ------------------------------
xlswrite(file_xls,headerY,'GHI', 'A1'); % Write the headers
xlswrite(file_xls,round(Table_GHI),'GHI','A2'); % Write the results

xlswrite(file_xls,headerY,'DNI','A1'); % Write the headers
xlswrite(file_xls,round(Table_DNI),'DNI','A2'); % Write the results

% NUMBER OF REPLACEMENTS AND REPLACED DAYS PER MONTH AND YEAR -------------
xlswrite(file_xls,headerY,'#_Replace','A1');
xlswrite(file_xls,round(Table_missing),'#_Replace','A2');

xlswrite(file_xls,hReplaced,'Replaced','A1');
xlswrite(file_xls,replaced_ex,'Replaced','A2');
