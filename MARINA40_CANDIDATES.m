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
% INPUT:
% ..\OUTPUT\3_VALIDATION
%       One Excel file with all years validation i.e. 'ASP00-BOM-01.xlsx'
%
% OUTPUT:
% ..\OUTPUT\4_CASES
%       Two Excel files:
%       ASP00-BOM-01-CANDIDATES.xlsx Sheets:
%       - CDFTotal_num: Long Term CDF (number of days) per each month
%           [---- Month ----- Val_BIN_1 Val_BIN_2 ... Val_BIN_end]
%       - CDFTotal_pct: Long Term CDF (cumulated percentage) per each month
%           [---- Month ----- Val_BIN_1 Val_BIN_2 ... Val_BIN_end]
%       - CDFyears_num: Each year CDF (number of days) per each month
%           [Year Month ----- Val_BIN_1 Val_BIN_2 ... Val_BIN_end]
%       - CDFyears_pct: Each year CDF (cumulated percentage) per each month
%           [Year Month ----- Val_BIN_1 Val_BIN_2 ... Val_BIN_end]
%       - Distance: Sorted distance between LT CDF and each month CDF
%           [Month Minor_distance ... Larger_distance]
%       - CANDIDATES: Sorted candidate years according with the distance
%           [Month #_Year_minor_distance ... #_Year_larger_distance]
%       - CDF_selTMY_num: TMY selected CDF (number of days) per each month
%           [Year Month ----- Val_BIN_1 Val_BIN_2 ... Val_BIN_end]
%       - CDF_selTMY_pct: TMY selected CDF (cumulated percentage) per each month
%           [Year Month ----- Val_BIN_1 Val_BIN_2 ... Val_BIN_end]
%       - outputTMY: Summary TMY methodology results
%           [Month Year_selected DNI_selected Long_Term_Average]
%       - CDF_selLMR_num: LMR selected CDF (number of days) per each month
%           [Year Month ----- Val_BIN_1 Val_BIN_2 ... Val_BIN_end]
%       - CDF_selLMR_pct: LMR selected CDF (cumulated percentage) per each month
%           [Year Month ----- Val_BIN_1 Val_BIN_2 ... Val_BIN_end]
%       - outputLMR: Summary LMR methodology results 
%           [Month Year_selected DNI_selected Long_Term_Average #_of_Missing_Records]
%       INPUT-GENERATION.xlsx Sheets:
%       - VARIABLE: Name of the main variable (GHI or DNI)
%       - INPUT: Number of the years selected for each month
%           [MONTH TMY_(Year_selected) LMR_(Year_selected)]
%       - OBJECTIVE: DNI or GHI values corresponding to the year selected for each month
%           [MONTH TMY_(Value) LMR_(Value)]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close, clearvars, %clc
run('Configuration_BSRN_ASP.m');

if ~exist(path_cases,'dir')
    mkdir(path_cases);
end

namef = [loc '00-' owner_station '-' num];
file_xls = strcat(path_val,'\',namef,'.xlsx'); % Name input file after validation

file_Out = strcat(path_cases,'\',namef,'-CANDIDATES.xlsx'); % Candidates
file_Input = strcat(path_cases,'\','INPUT-GENERATION.xlsx'); % Input Generation

% Switch off new excel sheet warning
warning off MATLAB:xlswrite:AddSheet

%% Reading the daily values
Val_Day = xlsread(file_xls, 'Val_Day'); % Text headers discarded
colDNId = 5:6:6*num_years; % Columns daily DNI data
% colGHId = 2:6:6*num_years; % Columns daily GHI data
DNI_d = Val_Day(:,colDNId); % Daily DNI data
% GHI_d = Val_Day(:,colGHId); % Daily GHI data

% Generation of a consecutive daily table
row = 0;
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
    month_ave(m) = mean(DNI_m(m,good_years));
    
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

% Excel report ------------------------------------------------------------
headers = cell(1,3+nbins);
headers{1} = '----';
headers{2} = 'Month';
headers{3} = '----';
for i = 1:nbins
    headers{i+3} = strcat('Bin_',num2str(i));
end

xlswrite(file_Out,[headers; num2cell(CDFT_num)],'CDFTotal_num','A1'); % Write LT CDF number of days
xlswrite(file_Out,[headers; num2cell(floor(CDFT_cumpct*100)/100)],'CDFTotal_pct','A1'); % Write LT CDF

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

% Excel report ------------------------------------------------------------
headers{1} = 'Year';
xlswrite(file_Out,[headers; num2cell(CDF_num)],'CDFyears_num','A1'); % Write CDF number of days per year
xlswrite(file_Out,[headers; num2cell(floor(CDF_cumpct*100)/100)],'CDFyears_pct','A1'); % Write CDF per year

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

years = year_ini:year_end; % Years analyzed
% Pre-allocation
headers_m = {'Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';'Ago';'Sep';'Oct';'Nov';'Dic'}; % Headers months
value = zeros(y,12); % Sorted summed absolute difference per month
sorted_y = zeros(y,12); % Sorted index
position_candidates = zeros(1,num_cand); % Sorted candidates years

% TMY pre-allocation (TYPICAL METEOROLOGICAL YEAR - SNL/NREL)
Year_selectedTMY = zeros(12,1); % Selected year closest month
Val_selectedTMY = zeros(12,1); % DNI monthly value closest month
CDF_selTMY_num = zeros(12,3+nbins); % Array to save the cumulative number of days of each bin per month
CDF_selTMY_cumpct = zeros(12,3+nbins); % Array to save the cumulative percent of each bin per month

% LMR pre-allocation (LESS MISSING RECORDS)
% Alternative methodology: Select months with fewer replacements
nNonvalid = xlsread(file_xls, '#_NonValid'); % Number of non-valid days in each month and year
nNonvalid(1,:) = []; % Trim headers (Years)
Year_selectedLMR = zeros(12,1); % Selected year less missing records month
Val_selectedLMR = zeros(12,1); % DNI monthly value less missing records month
nNV_selectedLMR = zeros(12,1); % Number of non-valid less missing records month
CDF_selLMR_num = zeros(12,3+nbins); % Array to save the cumulative number of days of each bin per month
CDF_selLMR_cumpct = zeros(12,3+nbins); % Array to save the cumulative percent of each bin per month

for m = 1:12
    [value(:,m), sorted_y(:,m)] = sort(results(:,m));
    CANDIDATES = sorted_y+year_ini-1;
    
    for cand = 1:num_cand
        position_candidates(cand) = find(years==CANDIDATES(cand,m));
    end
        
    % TMY METHODOLOGY - SNL/NREL ------------------------------------------
    % From the 'num_cand' months with lowest FS statistic, it is searched
    % the one with the closest value to the mean of the whole data set
    % Values of the candidates months
    Candidates_values = DNI_m(m,position_candidates); % Candidates monthly DNI values
    diff = abs(Candidates_values - month_ave(m)); % Difference between DNI monthly values and the whole data set mean value
    [~, pos_selecTMY] = min(diff); % Selected year
    
    Year_selectedTMY(m) = years(position_candidates(pos_selecTMY));
    Val_selectedTMY(m) = DNI_m(m,position_candidates(pos_selecTMY));
    % Save CDF of the chosen one
    CDF_selTMY_num(m,1) = Year_selectedTMY(m); CDF_selTMY_cumpct(m,1) = Year_selectedTMY(m);
    CDF_selTMY_num(m,2) = m; CDF_selTMY_cumpct(m,2) = m;
%     CDF_selTMY_num(m,3) = 0; CDF_selTMY_cumpct(m,3) = 0;

    posTMY = find(CDF_cumpct(:,1)==Year_selectedTMY(m) & CDF_cumpct(:,2)==m);
    CDF_selTMY_num(m,4:end) = CDF_num(posTMY,4:end); % TMY selected
    CDF_selTMY_cumpct(m,4:end) = CDF_cumpct(posTMY,4:end); % TMY selected
    
    % LMR METHODOLOGY -----------------------------------------------------
    % From the 'num_cand' months with lowest FS statistic, it is searched
    % the one with the LESS MISSING RECORDS among the candidates
    Candidates_missing = nNonvalid(m,position_candidates); % Candidates with fewer missing records
    [nNV_selectedLMR(m), pos_selecLMR] = min(Candidates_missing); % Selected year
    
    Year_selectedLMR(m) = years(position_candidates(pos_selecLMR));
    Val_selectedLMR(m) = DNI_m(m,position_candidates(pos_selecLMR));
    % Save CDF of the chosen one
    CDF_selLMR_num(m,1) = Year_selectedLMR(m); CDF_selLMR_cumpct(m,1) = Year_selectedLMR(m);
    CDF_selLMR_num(m,2) = m; CDF_selLMR_cumpct(m,2) = m;
%     CDF_selLMR_num(m,3) = 0; CDF_selLMR_cumpct(m,3) = 0;

    posLMR = find(CDF_cumpct(:,1)==Year_selectedLMR(m) & CDF_cumpct(:,2)==m);
    CDF_selLMR_num(m,4:end) = CDF_num(posLMR,4:end); % LMR selected
    CDF_selLMR_cumpct(m,4:end) = CDF_cumpct(posLMR,4:end); % LMR selected
    
    clear posTMY posLMR
end

%% Sorted Absolute differences & Candidates Output
dist_ex = [num2cell([NaN 1:size(value,1)]); [headers_m, num2cell(floor(value'*100)/100)]];
xlswrite(file_Out,dist_ex,'Distance','A1'); % Write the distance between LT CDF and each month CDF (statistic)

cand_ex = [num2cell([NaN 1:size(value,1)]); [headers_m, num2cell(CANDIDATES')]];
xlswrite(file_Out,cand_ex,'CANDIDATES','A1'); % Write the candidates years per month

%% TMY METHODOLOGY Output
outputTMY(:,1) = Year_selectedTMY; % 1st COLUMN, YEAR SELECTED
outputTMY(:,2) = Val_selectedTMY; % 2nd COLUMN, MONTHLY VALUE OF THE SELECTED MONTH
outputTMY(:,3) = floor(month_ave*100)/100; % 3rd COLUMN, MONTHLY MEAN OF THE VALID MONTHS (along all years)

% Write the selected TMY CDFs number of days
xlswrite(file_Out,[headers; num2cell(CDF_selTMY_num)],'CDF_selTMY_num','A1');
% Write the selected TMY CDFs
xlswrite(file_Out,[headers; num2cell(floor(CDF_selTMY_cumpct*100)/100)],'CDF_selTMY_pct','A1');
% Write TMY results
TMY_ex = [{'', 'Year', 'DNI TMY', 'LTA'}; [headers_m, num2cell(outputTMY)]];
xlswrite(file_Out,TMY_ex,'outputTMY','A1');

%% LMR METHODOLOGY Output
outputLMR(:,1) = Year_selectedLMR; % 1st COLUMN, YEAR SELECTED
outputLMR(:,2) = Val_selectedLMR; % 2nd COLUMN, MONTHLY VALUE OF THE SELECTED MONTH
outputLMR(:,3) = floor(month_ave*100)/100; % 3rd COLUMN, MONTHLY MEAN OF THE VALID MONTHS (along all years)
outputLMR(:,4) = nNV_selectedLMR; % 4th COLUMN, NUMBER OF MISSING RECORDS OF THE SELECTED MONTH

% Write the selected LMR CDFs number of days
xlswrite(file_Out,[headers; num2cell(CDF_selLMR_num)],'CDF_selLMR_num','A1');
% Write the selected LMR CDFs
xlswrite(file_Out,[headers; num2cell(floor(CDF_selLMR_cumpct*100)/100)],'CDF_selLMR_pct','A1');
% Write LMR results
LMR_ex = [{'', 'Year', 'DNI LMR', 'LTA', '#MR'}; [headers_m, num2cell(outputLMR)]];
xlswrite(file_Out,LMR_ex,'outputLMR','A1');

%% INPUT GENERATION
% Write the inputs for series generation
xlswrite(file_Input,{'DNI'},'VARIABLE','A1'); % Main variable

% Input
input_ex = [{'MONTH', 'TMY', 'LMR'}; [headers_m, num2cell([outputTMY(:,1), outputLMR(:,1)])]];
xlswrite(file_Input,input_ex,'INPUT','A1'); % Write candidates selected

% Objective
obj_ex = [{'MONTH', 'TMY', 'LMR'}; [headers_m, num2cell([outputTMY(:,2), outputLMR(:,2)])]];
xlswrite(file_Input,obj_ex,'OBJECTIVE','A1'); % Write objective DNI value

%% Figures
% Long Term CDF -----------------------------------------------------------
figCDFT = CDFT_cumpct(:,4:3+nbins)';
[mm,bb] = meshgrid(1:12,1:nbins);

figure; plot3(bb,mm,figCDFT) % Continous LT CDF
title('Long Term CDF'), xlabel('Bins'), ylabel('Months'), zlabel('CDF')
grid on, xlim([1 nbins]), ylim([1 12]), legend(headers_m)

figure; b = bar3(1:10,figCDFT); % Solid color bar LT CDF
for i = 1:size(figCDFT,2)
    cdata = b(i).CData;
    k = 1;
    for j = 0:6:(6*size(figCDFT,1)-6)
        cdata(j+1:j+6,:) = figCDFT(k,i);
        k = k+1;
    end
    b(i).CData = cdata;
end
% for k = 1:length(b) % % Gradient color bar LT CDF
%     zdata = b(k).ZData;
%     b(k).CData = zdata;
%     b(k).FaceColor = 'interp';
% end
colormap(jet)
title('Long Term CDF'), xlabel('Months'), ylabel('Bins'), zlabel('CDF')
view([-127 30]), xticklabels(headers_m)

% figure; h3 = axes; bar3(1:12,CDFT_cumpct(:,4:3+nbins)); % Color bar by bin
% title('Long Term CDF'), xlabel('Bins'), ylabel('Months'), zlabel('CDF')
% view([-34.7 38]), set(h3,'YTickLabel',headers_m,'YDir', 'reverse')

% CDF TMY selected --------------------------------------------------------
figCDFTMY = CDF_selTMY_cumpct(:,4:3+nbins)';
figure; plot3(bb,mm,figCDFTMY) % Continous CDF TMY
title('CDF TMY selected'), xlabel('Bins'), ylabel('Months'), zlabel('CDF')
grid on, xlim([1 nbins]), ylim([1 12]), legend(headers_m)

figure; b = bar3(1:10,figCDFTMY); % Solid color bar LT CDF
for i = 1:size(figCDFTMY,2)
    cdata = b(i).CData;
    k = 1;
    for j = 0:6:(6*size(figCDFTMY,1)-6)
        cdata(j+1:j+6,:) = figCDFTMY(k,i);
        k = k+1;
    end
    b(i).CData = cdata;
end
colormap(jet)
title('CDF TMY selected'), xlabel('Months'), ylabel('Bins'), zlabel('CDF')
view([-127 30]), xticklabels(headers_m)

% CDF LMR selected --------------------------------------------------------
figCDFLMR = CDF_selLMR_cumpct(:,4:3+nbins)';
figure; plot3(bb,mm,figCDFLMR) % Continous CDF LMR
title('CDF LMR selected'), xlabel('Bins'), ylabel('Months'), zlabel('CDF')
grid on, xlim([1 nbins]), ylim([1 12]), legend(headers_m)

figure; b = bar3(1:10,figCDFLMR); % Solid color bar LT CDF
for i = 1:size(figCDFLMR,2)
    cdata = b(i).CData;
    k = 1;
    for j = 0:6:(6*size(figCDFLMR,1)-6)
        cdata(j+1:j+6,:) = figCDFLMR(k,i);
        k = k+1;
    end
    b(i).CData = cdata;
end
colormap(jet)
title('CDF LMR selected'), xlabel('Months'), ylabel('Bins'), zlabel('CDF')
view([-127 30]), xticklabels(headers_m)

