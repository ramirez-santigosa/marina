%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% MODULE 4: TYPICAL METEOROLOGICAL MONTHS SELECTION BASED IN SEVERAL TMY
% METHODOLOGIES
% Version of July, 2015. L. Ramírez; At CSIRO.
% Update F. Mendoza (June 2017) at CIEMAT.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT:
% ..\OUTPUT\3_VALIDATION
%       One Excel file with all years validation i.e. 'loc00-owner_station-num'_VAL
%
% OUTPUT:
% ..\OUTPUT\4_TMYMETH
%       (1) Excel reports and graphs corresponding to each of the executed
%       TMY methodologies.
%       (2) 'loc00-owner_station-num'-IN_SERIESGEN.xlsx Sheets:
%       - VARIABLE: Name of the main variable (GHI or DNI)
%       - INPUT: Years/month selected for each methodology
%           [MONTH IEC1/SNL... F-R]
%       - OBJECTIVE: DNI or GHI values corresponding to the year/month
%       selected for each methodology
%           [MONTH IEC1/SNL... F-R]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close, clearvars -except cfgFile, %clc
run(cfgFile); % Run configuration file

if ~exist(path_meth,'dir')
    mkdir(path_meth);
end

namef = [loc '00-' owner_station '-' num];
file_xls = strcat(path_val,'\',namef,'_VAL','.xlsx'); % Name input file after validation

% Input for Series Generation (Summary of the methodologies outputs)
outYears = zeros(12,sum(methS)); %[outSNL(:,1), outLMR(:,1) outIEC2(:,1) outDRY(:,1) outFR(:,1)];
outRMV = zeros(12,sum(methS)); i_meth = 0; %[outSNL(:,2), outLMR(:,2) outIEC2(:,1) outDRY(:,1) outFR(:,1)];
mainVar = cell(1,sum(methS)); % Save main variable in each method
fInputGen = strcat(path_meth,'\',namef,'-IN_SERIESGEN.xlsx');

% Switch off new excel sheet warning
warning off MATLAB:xlswrite:AddSheet

%% Reading the daily values
Val_Day = xlsread(file_xls, 'Val_Day'); % Text headers discarded
colDNId = 6:6:6*num_years; % Columns daily DNI data
colGHId = 3:6:6*num_years; % Columns daily GHI data
DNI_d = Val_Day(:,colDNId); % Daily DNI data
GHI_d = Val_Day(:,colGHId); % Daily GHI data

% Generation of a consecutive daily table
row = 0;
data_day_DNI = zeros(365*num_years,4);
data_day_GHI = zeros(365*num_years,4);
for y = year_ini:year_end
    for m = 1:12
        for d = 1:num_days_m(m)
            row = row+1;
            data_day_DNI(row,1) = y; data_day_GHI(row,1) = y;
            data_day_DNI(row,2) = m; data_day_GHI(row,2) = m;
            data_day_DNI(row,3) = d; data_day_GHI(row,3) = d;
        end
    end
end

data_day_DNI(:,4) = reshape(DNI_d,[],1); % Adding daily values to the consecutive table
data_day_GHI(:,4) = reshape(GHI_d,[],1); % Adding daily values to the consecutive table

%% Reading the monthly data and flags
Val_Month = xlsread(file_xls, 'Val_Month');
colDNIm = 5:6:6*num_years; % Columns monthly DNI data
colGHIm = 2:6:6*num_years; % Columns monthly GHI data
colDNImf = 6:6:6*num_years; % Columns monthly DNI flag
colGHImf = 3:6:6*num_years; % Columns monthly GHI flag
DNI_m = Val_Month(:,colDNIm); % DNI monthly values
GHI_m = Val_Month(:,colGHIm); % GNI monthly values
DNI_mf = Val_Month(:,colDNImf); % DNI monthly validation flag
GHI_mf = Val_Month(:,colGHImf); % GHI monthly validation flag

% TMY Methodologies -------------------------------------------------------
%% IEC1/SNL
if methS(1)==1 % IEC1-SNL    
    % Calculation of the FS statistics and candidate months
    [CDFLT_num, CDFLT_cumpct, LTMM, CDFym_num, CDFym_cumpct, FS_DNI, candidates] = ...
        FS_statistic(data_day_DNI, nbins, DNI_m, DNI_mf, GHI_mf, num_cand);
    
    fOutIEC1SNL = strcat(path_meth,'\',namef,'-IEC1-SNL.xlsx'); % Output file Typical Meteorological Months (TMM) IEC1/SNL
    % IEC1/SNL Selection TMM methodology and report
    outSNL = ...
        tmyIEC1SNL(candidates, LTMM, CDFLT_num, CDFLT_cumpct, CDFym_num, CDFym_cumpct, fOutIEC1SNL);
    disp('IEC1/SNL methodology executed. TMM selected.');
    
    i_meth = i_meth+1; outYears(:,i_meth) = outSNL(:,1);
    outRMV(:,i_meth) = outSNL(:,2);
    mainVar{1,i_meth} = 'DNI';
    close all
end
%% IEC1/LMR
if methS(2)==1 % IEC1-LMR
    if methS(1)==0 % Obtain candidates months just if IEC1/SNL was not executed
        % Calculation of the FS statistics and candidate months
        [CDFLT_num, CDFLT_cumpct, ~, CDFym_num, CDFym_cumpct, FS_DNI, candidates] = ...
            FS_statistic(data_day_DNI, nbins, DNI_m, DNI_mf, GHI_mf, num_cand);
    end
    
    fOutIEC1LMR = strcat(path_meth,'\',namef,'-IEC1-LMR.xlsx'); % Output file TMM IEC1/LMR
    % IEC1/LMR Selection TMM methodology and report
    outLMR = ...
        tmyIEC1LMR(candidates, file_xls, CDFLT_num, CDFLT_cumpct, CDFym_num, CDFym_cumpct, fOutIEC1LMR);
    disp('IEC1/LMR methodology executed. TMM selected.');
    
    i_meth = i_meth+1; outYears(:,i_meth) = outLMR(:,1);
    outRMV(:,i_meth) = outLMR(:,2);
    mainVar{1,i_meth} = 'DNI';
    close all
end
%% IEC2
if methS(3)==1 % IEC2
    
    fOutIEC2 = strcat(path_meth,'\',namef,'-IEC2.xlsx'); % Output file TMM IEC2
    % IEC2 RMV calculation and report
    outIEC2 = tmyIEC2(fileInIEC2,fOutIEC2,GHI_m,year_ini:year_end); % Dummy function TO DO !!!
    disp('IEC2 methodology executed. RMV determined.');
    
    i_meth = i_meth+1; outYears(:,i_meth) = outIEC2(:,1);
    outRMV(:,i_meth) = outIEC2(:,2);
    mainVar{1,i_meth} = 'GHI';
    close all
end
%% Danish method (DRY)
if methS(4)==1 % DRY
    
    fOutDRY = strcat(path_meth,'\',namef,'-DRY.xlsx'); % Output file TMM DRY
    % DRY Selection TMM methodology and report
    outDRY = tmyDRY(data_day_DNI, data_day_GHI, DNI_m, DNI_mf, fOutDRY);
    disp('DRY methodology executed. TMM selected.');
    
    i_meth = i_meth+1; outYears(:,i_meth) = outDRY(:,1);
    outRMV(:,i_meth) = outDRY(:,2);
    mainVar{1,i_meth} = 'DNI';
    close all
end
%% Festa-Ratto (F-R)
if methS(5)==1 % F-R
    
    fOutFR = strcat(path_meth,'\',namef,'-FR.xlsx'); % Output file TMM F-R
    % F-R Selection TMM methodology and report
    outFR = tmyFR(data_day_DNI, DNI_m, DNI_mf, nbins, fOutFR);
    disp('F-R methodology executed. TMM selected.');
    
    i_meth = i_meth+1; outYears(:,i_meth) = outFR(:,1);
    outRMV(:,i_meth) = outFR(:,2);
    mainVar{1,i_meth} = 'DNI';
    close all
end

%% INPUT FOR SERIES GENERATION
% Write the inputs for series generation
meth_head = {'IEC1/SNL', 'IEC1/LMR', 'IEC2', 'DRY', 'F-R'};
xlswrite(fInputGen,[meth_head(logical(methS)); mainVar],'VARIABLE','A1'); % Main variable

headers_m = {'Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';'Aug';'Sep';'Oct';'Nov';'Dic'}; % Headers months
input_head = {'MONTH' meth_head{logical(methS)}};

% Input
input_ex = [input_head; [headers_m, num2cell(outYears)]];
xlswrite(fInputGen,input_ex,'INPUT','A1'); % Write candidates selected

% Objective
obj_ex = [input_head; [headers_m, num2cell(outRMV)]];
xlswrite(fInputGen,obj_ex,'OBJECTIVE','A1'); % Write objective DNI value
