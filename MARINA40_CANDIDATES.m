%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% MODULE 4: CANDIDATES FOR THE TMY GENERATION BASED IN CDF DISTANCES
% Version of July, 2015. L. Ramírez; At CSIRO.
% Update F. Mendoza (March 2017) at CIEMAT.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUTS
% ..\OUTPUT\3_VALIDATION
%       One Excel file per year i.e. 'ASP00-BOM-01.xlsx'
%       !!! datos_dia [AÑO MES DIA VALOR_DIARIO]
%
% OUTPUT !!!
% ..\OUTPUT\4_CASES
%       ASP00-BOM-01-CANDIDATOS.xlsx';
%       (1) Tables with the whole data 12 rows
%           CDFT_num (value) [  0 MONTH 0 VAL_INT1 VAL_INT2 ... VAL_INT_fin]
%           CDFT_por (perct) [  0 MONTH 0 VAL_INT1 VAL_INT2 ... VAL_INT_fin]
%       (2)Tables with a row for each month
%           CDF_num (value) [YEAR MONTH 0 VAL_INT1 VAL_INT2 ... VAL_INT_fin]
%           CDF_por (perct) [YEAR MONTH 0 VAL_INT1 VAL_INT2 ... VAL_INT_fin]
%       INPUT-GENERATION.xlsx';
%        File with 3 Sheets:
%           VARIABLE:   name of the main variable in A1 (GHI / DNI)
%           INPUT:      number of the years selected for each month
%                       columns from B (B2:B13)to number of cases
%           OBJECTIVE:  values that would like to be reached for each month
%                       columns from B (B2:B13)to number of cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close, clearvars, %clc
run('Configuration_BSRN_ASP.m');

if ~exist(path_cases,'dir')
    mkdir(path_cases);
end

num_years = year_end-year_ini+1;
namef = [loc '00-' owner_station '-' num];
file_xls = strcat(path_val,'\',namef,'.xlsx'); % Name input file after validation

file_Out = strcat(path_cases,'\',namef,'-CANDIDATES.xlsx'); % Candidates
file_Input = strcat(path_cases,'\','INPUT-GENERATION.xlsx'); % Input Generation

% Switch off new excel sheet warning
warning off MATLAB:xlswrite:AddSheet

%% Reading the daily values !¿Porque no directamente de Matlab?
Val_Day = xlsread(file_xls, 'Val_Day'); % Text headers discarded
colDNId = 5:6:6*num_years; % Columns daily DNI data
% colGHId = 2:6:6*num_years; % Columns daily GHI data
DNI_d = Val_Day(:,colDNId); % Daily DNI data
% GHI_d = Val_Day(:,colGHId); % Daily GHI data

% Generation of a consecutive daily table
row = 0;
num_days = [31 28 31 30 31 30 31 31 30 31 30 31];
data_day = zeros(365*num_years,4);

for y = year_ini:year_end
    for m = 1:12
        for d = 1:num_days(m)
            row = row+1;
            data_day(row,1) = y;
            data_day(row,2) = m;
            data_day(row,3) = d;
        end
    end
end

data_day(:,4) = reshape(DNI_d,[],1); % Adding daily values to the consecutive table

%% Reading the monthly flags
Val_Month = xlsread(file_xls, 'Val_Month');
colDNImf = 6:6:6*num_years; % Columns monthly DNI flag
colGHImf = 3:6:6*num_years; % Columns monthly GHI flag
DNI_m = Val_Month(:,colDNId); % DNI monthly values
DNI_mf = Val_Month(:,colDNImf); % DNI monthly validation flag
GHI_mf = Val_Month(:,colGHImf); % GHI monthly validation flag

%% Evaluating CDF for each month (along all years)
nbins = 10; % Number of bins for cumulative distribution function
maximum = max(data_day(:,4)); % Maximum daily DNI along all years
% Pre-allocating
month_ave = zeros(12,1); % Average montly DNI along all years
CDFT_num = zeros(12,3+nbins); % Array to save the cumulative number of days of each bin along all years
CDFT_cumpct = zeros(12,3+nbins); % Array to save the cumulative percent of each bin along all years

for m = 1:12
    
    pos_m = data_day(:,2)==m;
    
    % Calculating the monthly mean
%     good_years = (DNI_mf(m,:)==1 & GHI_mf(m,:)==1);
    good_years = DNI_mf(m,:)==1; % Flag monthly validation !!!
    month_ave(m,1) = mean(DNI_m(m,good_years));
    
    % Removing positions of the bad years
    bad_years = find(DNI_mf(m,:)~=1 & GHI_mf(m,:)~=1);
    bad_years = bad_years+year_ini-1; % Get the number of the years which months aren't valid
    
    if any(bad_years)
        for bad = 1:length(bad_years)
            pos_bad = (data_day(:,2)==m & data_day(:,1)==bad_years(bad));
            pos_m = xor(pos_m,pos_bad); % XOR instead of minus to keep logical index
            clear pos_bad
        end
    end
    
%     CDFT_num(m,1) = 0;
    CDFT_num(m,2) = m;
%     CDFT_num(m,3) = 0;
    
%     CDFT_cumpct(m,1) = 0;
    CDFT_cumpct(m,2) = m;
%     CDFT_cumpct(m,3) = 0;
    
    [CDFT_num(m,4:end), CDFT_cumpct(m,4:end)] = CDF_general(data_day(pos_m,4),maximum,nbins); % Function
end

% Excel report
headers = cell(1,3+nbins);
headers{1} = '----';
headers{2} = 'Month';
headers{3} = '----';

for i = 1:nbins
    headers{i+3} = strcat('Bin_',num2str(i));
end

xlswrite(file_Out,headers,'CDFTotal_num','A1'); % Write the headers
xlswrite(file_Out,CDFT_num,'CDFTotal_num','A2'); % Write the results

xlswrite(file_Out,headers,'CDFTotal_pct','A1'); % Write the headers
xlswrite(file_Out,floor(CDFT_cumpct*100)/100,'CDFTotal_pct','A2'); % Write the results

%% CDF of each individual month (each year)
row = 0;
CDF_num = zeros(num_years*12,3+nbins); % Array to save the cumulative number of days of each bin per month
CDF_cumpct = zeros(num_years*12,3+nbins); % Array to save the cumulative percent of each bin per month

for y = year_ini:year_end
    for m = 1:12
        row = row+1;
        pos_m = (data_day(:,1)==y & data_day(:,2)==m);
        CDF_num(row,1) = y;
        CDF_num(row,2) = m;
        CDF_num(row,3) = 0;
        
        CDF_cumpct(row,1) = y;
        CDF_cumpct(row,2) = m;
        CDF_cumpct(row,3) = 0;
        
        [CDF_num(row,4:3+nbins), CDF_cumpct(row,4:3+nbins)] = CDF_general(data_day(pos_m,4),maximum,nbins); % Function
    end
end

headers{1} = 'Year';

xlswrite(file_Out,headers,'CDFyears_num','A1'); % Write the headers
xlswrite(file_Out,CDF_num,'CDFyears_num','A2'); % Write the results

xlswrite(file_Out,headers,'CDFyears_pct','A1'); % Write the headers
xlswrite(file_Out,floor(CDF_cumpct*100)/100,'CDFyears_pct','A2'); % Write the results

disp('Candidates selected!');

%% Generation of main output tables (Values & Candidates)
spreadsheet_pct = reshape(CDF_cumpct(:,4:3+nbins)',nbins,12,[]); % Reshape per Bins X Months X Years
[~,~,y] = size(spreadsheet_pct); % Number of years

absDiff = zeros(12,nbins,y); % Absolute difference between the long-term CDF and each month CDF (sheet per year)
sum_m = zeros(12,1,y); % Sum of differences per month along all bins (sheet per year)
results = zeros(y,12); % Summary array of results (Years X Months)

for i = 1:y
    sheet_y = spreadsheet_pct(:,:,i)';
    absDiff(:,1:nbins,i) = abs(CDFT_cumpct(:,4:3+nbins)-sheet_y);
    sum_m(:,:,i) = sum(absDiff(:,:,i),2);
    results(i,:) = sum_m(:,:,i)';
end

years = year_ini:year_end;
num_pre = 3; % Number of pre-selected candidates. Must be < number of years
% Pre-allocation
headers_m = cell(1,12); % Headers months
value = zeros(y,12); % Sorted summed absolute difference per month
pos_candidate = zeros(y,12); % Sorted index
position_preselected = zeros(1,num_pre); % Sorted number of years
% TMY pre-allocation
Val_selectedTMY = zeros(1,12); % DNI monthly value closest month
Year_selectedTMY = zeros(1,12); % Selected year closest month
CDF_sel1 = zeros(12,3); % Save date
CDF_sel1_num = zeros(12,3+nbins); % Array to save the cumulative number of days of each bin per month
CDF_sel1_cumpct = zeros(12,3+nbins); % Array to save the cumulative percent of each bin per month
% LMR1 pre-allocation
% Voy a probar a selecionar el mes con menos cambios.???
nNonvalid = xlsread(file_xls, '#_NonValid');
nNonvalid(1,:) = []; % Trim headers (Years)
Val_selectedLMR1 = zeros(1,12); 
Year_selectedLMR1 = zeros(1,12);
CDF_sel2 = zeros(12,3); % Save date
CDF_sel2_num = zeros(12,3+nbins); % Array to save the cumulative number of days of each bin per month
CDF_sel2_cumpct = zeros(12,3+nbins); % Array to save the cumulative percent of each bin per month

for m = 1:12
    headers_m{m} = strcat('Month_',num2str(m));
    [value(:,m), pos_candidate(:,m)] = sort(results(:,m));
    CANDIDATES = pos_candidate+year_ini-1;
    
    % TMY METHODOLOGY
    % With the 5 lowest, search the month closest to the mean preselected 
    % positions in the years
    for pre = 1:num_pre
        position_preselected(pre) = find(years==CANDIDATES(pre,m));
    end
    
    % Values of the preselected months
    Preselected_values = DNI_m(m,position_preselected); % Preselected monthly DNI values
    diff = abs(Preselected_values - month_ave(m,1)); % Difference between DNI monthly values and the average value
    [~, pos_selecTMY] = min(diff); % Selected year
    
    Val_selectedTMY(m) = DNI_m(m,position_preselected(pos_selecTMY));
    Year_selectedTMY(m) = years(position_preselected(pos_selecTMY));
    % Save CDF of the first selection
    CDF_sel1(m,1) = Year_selectedTMY(m);
    CDF_sel1(m,2) = m;
    CDF_sel1(m,3) = 0;
    pos1 = find(CDF_cumpct(:,1)==Year_selectedTMY(m) & CDF_cumpct(:,2)==m);
    CDF_sel1_num(m,4:13) = CDF_num(pos1,4:13);
    CDF_sel1_cumpct(m,4:13) = CDF_cumpct(pos1,4:13);
    
    % LMR1 METHODOLOGY
    % With the 5 lowest, search the LESS MISSING RECORDS
    % preselected positions in the years
    % values of the preselected months
    Preselected_missing = nNonvalid(m,position_preselected);
    Min_faltan = min(Preselected_missing);
    pos_selecLMR = find (Preselected_missing==Min_faltan);
    
    Val_selectedLMR1(m) = DNI_m(m,position_preselected(pos_selecLMR(1)));
    Year_selectedLMR1(m) = years(position_preselected(pos_selecLMR(1)));
    % almacena las CDF de la primera selección???!
    CDF_sel2(m,1) = Year_selectedLMR1(m);
    CDF_sel2(m,2) = m;
    CDF_sel2(m,3) = 0;
    pos2 = find(CDF_cumpct(:,1)==Year_selectedLMR1(m) & CDF_cumpct(:,2)==m);
    CDF_sel2_num(m,4:13) = CDF_num(pos2,4:13);
    CDF_sel2_cumpct(m,4:13) = CDF_cumpct(pos2,4:13);
    
    clear pos1 pos2
end

%% TMY METHODOLOGY
output1(1,:) = Year_selectedTMY'; %  1ST COLUMN, YEAR SELECTED
output1(2,:) = Val_selectedTMY';  %  2ND COLUMN, MONTHLY VALUE OF THE SELECTED MONTH
output1(4,:) = floor(month_ave');   %4TH COLUMN, MONTHLY MEAN OF THE VALID MONTHS

xlswrite(file_Out,headers,'CDF_sel1_num','A1'); % Write the headers
xlswrite(file_Out,CDF_sel1_num,'CDF_sel1_num','A2'); % Write the results

xlswrite(file_Out,headers,'CDF_sel1_cumpct','A1');
xlswrite(file_Out,floor(CDF_sel1_cumpct*100)/100,'CDF_sel1_cumpct','A2');

xlswrite(file_Out,headers_m','distances','A1');
xlswrite(file_Out,floor(value'),'distances','B1');

xlswrite(file_Out,headers_m','CANDIDATES','A1');
xlswrite(file_Out,CANDIDATES','CANDIDATES','B1');

xlswrite(file_Out,headers_m','output1','A1');
xlswrite(file_Out,output1','output1','B1');

% Write the inputs for series generation
xlswrite(file_Input,{'DNI'},'VARIABLE', 'A1'); % Write the headers

xlswrite(file_Input,[{'MONTH'} {'TMY'}],'INPUT', 'A1');
xlswrite(file_Input,headers_m','INPUT','A2');
xlswrite(file_Input,output1(1,:)','INPUT','B2'); % Write the results

xlswrite(file_Input,[{'MONTH'} {'TMY'}],'OBJECTIVE','A1');
xlswrite(file_Input,headers_m','OBJECTIVE','A2');
xlswrite(file_Input,output1(2,:)','OBJECTIVE','B2');

%% LMR1 METHODOLOGY
output2(1,:) = Year_selectedLMR1'; % 1ST COLUMN, YEAR SELECTED
output2(2,:) = Val_selectedLMR1'; % 2ND COLUMN, MONTHLY VALUE OF THE SELECTED MONTH
output2(4,:) = floor(month_ave'); % 4TH COLUMN, MONTHLY MEAN OF THE VALID MONTHS

xlswrite(file_Out,headers,'CDF_sel2_num','A1'); % Write the headers
xlswrite(file_Out,CDF_sel2_num,'CDF_sel2_num','A2'); % Write the results

xlswrite(file_Out,headers,'CDF_sel2_cumpct','A1');
xlswrite(file_Out,floor(CDF_sel2_cumpct*100)/100,'CDF_sel2_cumpct','A2');

xlswrite(file_Out,headers_m','output2','A1');
xlswrite(file_Out,output2','output2','B1');

% Write the inputs for series generation
xlswrite(file_Input,{'LMR'},'INPUT','C1'); % Write the headers
xlswrite(file_Input,output2(1,:)','INPUT','C2'); % Write the results

xlswrite(file_Input,{'LMR'},'OBJECTIVE', 'C1');
xlswrite(file_Input,output2(2,:)','OBJECTIVE','C2');
