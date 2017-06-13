function [ outLMR ] = ...
    tmyIEC1LMR( candidates, file_xls, CDFLT_num, CDFLT_cumpct, CDFym_num, CDFym_cumpct, fileOut )
%TMYIEC1LMR Selects the TMM according to the IEC1/LMR methodology. Writes
%down a corresponding report and print graphs.
%   INPUT:
%   candidates: Structure with two fields
%       candidates.years: Years of the candidate months (12 rows X num_cand columns)
%       candidates.values: DNI monthly values of the candidate months (12 rows X num_cand columns)
%   file_xls: File with the results of the validation process
%   CDFLT_num: Long-term CDF in number of days in each bin (12 rows X
%   2+nbins columns)
%   CDFLT_cumpct: Long-term CDF in percent of days in each bin (12 rows X
%   2+nbins columns)
%   CDFym_num: Individual month CDF in number of days in each bin
%   (num_yearsX12 rows X 2+nbins columns)
%   CDFym_cumpct: Individual month CDF in percent of days in each bin
%   (num_yearsX12 rows X 2+nbins columns)
%   fileOut: Name of the output report with the results of the methodology
%
%   OUTPUT:
%   outLMR: Results of the selected TMM with the IEC1/LMR methodology
%       1st column: Selected year of the TMM
%       2nd column: Monthly value of the selected TMM
%       3rd column: LTMM
%
% - F. Mendoza (June 2017) Update

nbins = size(CDFym_cumpct,2)-2; % Minus Year and Month columns
year_ini = CDFym_cumpct(1,1);
years = candidates.years; % Candidate years for TMM
i_years = years-year_ini+1; % Candidate years for TMM index
values = candidates.values; % DNI monthly value of the candidates for TMM
nNonvalid = xlsread(file_xls, '#_NonValid'); % Number of non-valid days in each month and year
nNonvalid(1,:) = []; % Trim headers (Years)
% IEC1/LMR pre-allocation (Less Missing Records)
Year_selLMR = zeros(12,1); % Selected year less missing records month
Val_selLMR = zeros(12,1); % DNI monthly value less missing records month
nNV_selLMR = zeros(12,1); % Number of non-valid less missing records month
CDF_selLMR_num = zeros(12,2+nbins); % Array to save the cumulative number of days of each bin per month
CDF_selLMR_cumpct = zeros(12,2+nbins); % Array to save the cumulative percent of each bin per month

% IEC1/LMR METHODOLOGY ----------------------------------------------------
% Alternative methodology: Select months with fewer replacements
% From the 'num_cand' months with lowest FS statistic, it is searched
% the one with the Less Missing Records among the candidates
for m = 1:12
    Candidates_missing = nNonvalid(m,i_years(m,:)); % # of non-valid days of the candidates
    [nNV_selLMR(m), i_selLMR] = min(Candidates_missing); % Selected year
    
    Year_selLMR(m) = years(m,i_selLMR);
    Val_selLMR(m) = values(m,i_selLMR);
    
    % Save CDF of the chosen one
    CDF_selLMR_num(m,1) = Year_selLMR(m); CDF_selLMR_cumpct(m,1) = Year_selLMR(m);
    CDF_selLMR_num(m,2) = m; CDF_selLMR_cumpct(m,2) = m;
    posTMM = find(CDFym_cumpct(:,1)==Year_selLMR(m) & CDFym_cumpct(:,2)==m);
    CDF_selLMR_num(m,3:end) = CDFym_num(posTMM,3:end); % LMR selected
    CDF_selLMR_cumpct(m,3:end) = CDFym_cumpct(posTMM,3:end); % LMR selected
end

%% IEC1/LMR TMY METHODOLOGY output report
% LT CDF report -----------------------------------------------------------
headers = cell(1,2+nbins);
headers{1} = '----'; headers{2} = 'Month';
for i = 1:nbins
    headers{i+2} = ['Bin ' num2str(i)];
end

xlswrite(fileOut,[headers; num2cell(CDFLT_num)],'CDFLT_num','A1'); % Write LT CDF number of days
xlswrite(fileOut,[headers; num2cell(floor(CDFLT_cumpct*100)/100)],'CDFLT','A1'); % Write LT CDF

% Individual months CDF report --------------------------------------------
headers{1} = 'Year';
xlswrite(fileOut,[headers; num2cell(CDFym_num)],'CDFym_num','A1'); % Write CDF number of days per year
xlswrite(fileOut,[headers; num2cell(floor(CDFym_cumpct*100)/100)],'CDFym','A1'); % Write CDF per year

% Candidate years/month report --------------------------------------------
headers_m = {'Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';'Aug';'Sep';'Oct';'Nov';'Dic'}; % Headers months
cand_y_ex = [num2cell([NaN 1:size(years,2)]); [headers_m, num2cell(years)]];
xlswrite(fileOut,cand_y_ex,'Candidates_y','A1'); % Write the candidates years for TMM

cand_v_ex = [num2cell([NaN 1:size(values,2)]); [headers_m, num2cell(values)]];
xlswrite(fileOut,cand_v_ex,'Candidates_DNI','A1'); % Write the candidates for TMM

% Selected TMM CDFs number of days report ---------------------------------
xlswrite(fileOut,[headers; num2cell(CDF_selLMR_num)],'CDF_selLMR_num','A1');
% Selected TMM CDFs -------------------------------------------------------
xlswrite(fileOut,[headers; num2cell(floor(CDF_selLMR_cumpct*100)/100)],'CDF_selLMR','A1');

% IEC1/LMR output ---------------------------------------------------------
outLMR(:,1) = Year_selLMR; % 1st column: Selected year of the TMM
outLMR(:,2) = Val_selLMR; % 2nd column: Monthly value of the selected TMM
outLMR(:,3) = nNV_selLMR; % 4th column: Number of missing records of the TMM
LMR_ex = [{'', 'Year', 'DNI LMR', '#MR'}; [headers_m, num2cell(outLMR)]];
xlswrite(fileOut,LMR_ex,'outputLMR','A1');

%% Figures
% Long Term CDF -----------------------------------------------------------
figCDFLT = CDFLT_cumpct(:,3:end);
titleFig = 'Long-term CDF'; fileName = [fileOut(1:end-8) 'CDFLT-LMR'];
plotCDF3D(figCDFLT,titleFig,fileName)

% CDF TMY selected --------------------------------------------------------
figCDFLMR = CDF_selLMR_cumpct(:,3:end);
titleFig = 'CDF LMR selected'; fileName = [fileOut(1:end-8) 'CDFTMM-LMR'];
plotCDF3D(figCDFLMR,titleFig,fileName)

end
