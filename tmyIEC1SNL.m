function [ outSNL ] = ...
    tmyIEC1SNL( candidates, LTMM, CDFLT_num, CDFLT_cumpct, CDFym_num, CDFym_cumpct, fileOut )
%TMYIEC1SNL Selects the TMM according to the IEC1/SNL methodology. Writes
%down a corresponding report and print graphs.
%   INPUT:
%   candidates: Structure with two fields
%       candidates.years: Years of the candidate months (12 rows X num_cand columns)
%       candidates.values: DNI monthly values of the candidate months (12 rows X num_cand columns)
%   LTMM: Long-term monthly mean (each month). Simple average of the
%   monthly values (12 rows X 1)
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
%   outSNL: Results of the selected TMM with the IEC1/SNL methodology
%       1st column: Selected year of the TMM
%       2nd column: Monthly value of the selected TMM
%       3rd column: LTMM
%
% - F. Mendoza (June 2017) Update

nbins = size(CDFym_cumpct,2)-2; % Minus Year and Month columns
years = candidates.years; % Candidate years for TMM
values = candidates.values; % DNI monthly value of the candidates for TMM
% IEC1/SNL pre-allocation
Year_selSNL = zeros(12,1); % Selected year closest month
Val_selSNL = zeros(12,1); % DNI monthly value closest month
CDF_selSNL_num = zeros(12,2+nbins); % Array to save the cumulative number of days of each bin per month
CDF_selSNL_cumpct = zeros(12,2+nbins); % Array to save the cumulative percent of each bin per month

% IEC1/SNL METHODOLOGY ----------------------------------------------------
% From the 'num_cand' months with lowest FS statistic, it is searched
% the one with the closest value to the LTMM of each month
diff = abs(values - LTMM); % Difference between candidates months DNI value and LTMM
[~, i_selSNL] = min(diff,[],2); % Selected year

for m = 1:12
    Year_selSNL(m) = years(m,i_selSNL(m));
    Val_selSNL(m) = values(m,i_selSNL(m));
    
    % Save CDF of the chosen one
    CDF_selSNL_num(m,1) = Year_selSNL(m); CDF_selSNL_cumpct(m,1) = Year_selSNL(m);
    CDF_selSNL_num(m,2) = m; CDF_selSNL_cumpct(m,2) = m;
    posTMM = find(CDFym_cumpct(:,1)==Year_selSNL(m) & CDFym_cumpct(:,2)==m);
    CDF_selSNL_num(m,3:end) = CDFym_num(posTMM,3:end); % TMM selected
    CDF_selSNL_cumpct(m,3:end) = CDFym_cumpct(posTMM,3:end); % TMM selected
end

%% IEC1/SNL TMY METHODOLOGY output report
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
xlswrite(fileOut,[headers; num2cell(CDF_selSNL_num)],'CDF_selSNL_num','A1');
% Selected TMM CDFs -------------------------------------------------------
xlswrite(fileOut,[headers; num2cell(floor(CDF_selSNL_cumpct*100)/100)],'CDF_selSNL','A1');

% IEC1/SNL output ---------------------------------------------------------
outSNL(:,1) = Year_selSNL; % 1st column: Selected year of the TMM
outSNL(:,2) = Val_selSNL; % 2nd column: Monthly value of the selected TMM
outSNL(:,3) = floor(LTMM*100)/100; % 3rd column: LTMM
SNL_ex = [{'', 'Year', 'RMV IEC1/SNL (kWh/m2)', 'LTMM'}; [headers_m, num2cell(outSNL)]];
xlswrite(fileOut,SNL_ex,'outputSNL','A1');

%% Figures
% Long Term CDF -----------------------------------------------------------
figCDFLT = CDFLT_cumpct(:,3:end);
titleFig = 'Long-term CDF'; fileName = [fileOut(1:end-8) 'CDFLT-SNL'];
plotCDF3D(figCDFLT,titleFig,fileName)

% CDF TMY selected --------------------------------------------------------
figCDFSNL = CDF_selSNL_cumpct(:,3:end);
titleFig = 'CDF SNL selected'; fileName = [fileOut(1:end-8) 'CDFTMM-SNL'];
plotCDF3D(figCDFSNL,titleFig,fileName)

end
