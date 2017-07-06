function [ CDFLT_num, CDFLT_cumpct, LTMM, CDFym_num, CDFym_cumpct, FS, candidates ] = ...
    FS_statistic( data_day_DNI, nbins, DNI_m, DNI_mf, GHI_mf, num_cand )
%FS_STATISTIC Calculates the Finkelstein-Schafer (FS) statistic of one
%variable of each individual month
%   INPUT:
%   data_day: Input daily series (n days X [YYYY MM DD DNI_values])
%   nbins: Number of bins for CDF creation
%   DNI_m = DNI monthly values (12 rows X n years columns)
%   DNI_mf: Monthly DNI validation flag of each month
%   GHI_mf: Monthly GHI validation flag of each month
%   num_cand: Number of candidates to be selected (lowest FS)
%
%   OUTPUT:
%   CDFLT_num: Long-term CDF in number of days in each bin (12 rows X
%   2+nbins columns)
%   CDFLT_cumpct: Long-term CDF in percent of days in each bin (12 rows X
%   2+nbins columns)
%   LTMM: Long-term monthly mean (each month). Simple average of the
%   monthly values (12 rows X 1)
%   CDFym_num: Individual month CDF in number of days in each bin
%   (num_yearsX12 rows X 2+nbins columns)
%   CDFym_cumpct: Individual month CDF in percent of days in each bin
%   (num_yearsX12 rows X 2+nbins columns)
%   FS: FS statistic of each individual month (12 rows X num_years columns)
%   candidates: Structure with two fields
%       candidates.years: Years of the candidate months (12 rows X num_cand columns)
%       candidates.values: DNI monthly values of the candidate months (12 rows X num_cand columns)
%
% - F. Mendoza (June 2017) Update

maximum = max(data_day_DNI(:,4)); % Maximum daily DNI along all years
year_ini = data_day_DNI(1,1); % Initial year
year_end = data_day_DNI(end,1); % Final year
n_years = year_end-year_ini+1; % Number of years
years = year_ini:year_end; % Years analyzed

%% Monthly long-term CDF (each month along all years)
% Pre-allocating
CDFLT_num = NaN(12,2+nbins); % Array to save the cumulative number of days of each bin along all years
CDFLT_cumpct = NaN(12,2+nbins); % Array to save the cumulative percent of each bin along all years
LTMM = NaN(12,1); % Average monthly DNI along all years (whole data set long term monthly mean)

for m = 1:12      
    pos_m = data_day_DNI(:,2)==m;
    
    % Calculating the monthly mean
%     good_years = (DNI_mf(m,:)==1 & GHI_mf(m,:)==1);
    good_years = DNI_mf(m,:)==1; % Flag monthly validation !!!
    LTMM(m) = mean(DNI_m(m,good_years));
    
    % Removing positions of the bad years
    bad_years = find(DNI_mf(m,:)~=1 & GHI_mf(m,:)~=1);
    bad_years = bad_years+year_ini-1; % Get the number of the years which months aren't valid
    if any(bad_years)
        for bad = 1:length(bad_years)
            pos_bad = (data_day_DNI(:,2)==m & data_day_DNI(:,1)==bad_years(bad));
            pos_m = xor(pos_m,pos_bad); % XOR instead of minus to keep logical index
            clear pos_bad
        end
    end
    
    % CDFLT_num(m,1) = 0;
    CDFLT_num(m,2) = m;  
    % CDFLT_cumpct(m,1) = 0;
    CDFLT_cumpct(m,2) = m;
    
    [CDFLT_num(m,3:end), CDFLT_cumpct(m,3:end)] = CDF_general(data_day_DNI(pos_m,4),maximum,0,nbins); % Function
end

%% CDF of each individual month (each year, month)
% Pre-allocating
row = 0;
CDFym_num = NaN(n_years*12,2+nbins); % Array to save the cumulative number of days of each bin per month
CDFym_cumpct = NaN(n_years*12,2+nbins); % Array to save the cumulative percent of each bin per month

for y = years
    i_y = y-year_ini+1;
    for m = 1:12
        row = row+1;
        CDFym_num(row,1) = y;
        CDFym_num(row,2) = m;
        CDFym_cumpct(row,1) = y;
        CDFym_cumpct(row,2) = m;
        if DNI_mf(m,i_y)==1 % Flag monthly validation !!! Good month
            pos_m = (data_day_DNI(:,1)==y & data_day_DNI(:,2)==m);
            [CDFym_num(row,3:end), CDFym_cumpct(row,3:end)] = CDF_general(data_day_DNI(pos_m,4),maximum,0,nbins); % Function
        end
    end
end

%% Calculation of the FS statistic of each individual month
% Pre-allocation
absDiff_y = zeros(12,nbins,n_years); % Absolute difference between the long-term CDF and each month CDF (sheet per year)
FS_y = zeros(12,1,n_years); % FS statistic (sheet per year)

spreadsheet_pct = reshape(CDFym_cumpct(:,3:end)',nbins,12,[]); % Reshape per Bins X Months X Years
for i = 1:n_years
    sheet_y = spreadsheet_pct(:,:,i)';
    absDiff_y(:,:,i) = abs(CDFLT_cumpct(:,3:end)-sheet_y);
    FS_y(:,:,i) = sum(absDiff_y(:,:,i),2);
end

FS = reshape(FS_y,12,n_years); % Reshape (Months X Years)

%% Candidate months
% Pre-allocation
values = zeros(12,num_cand); % DNI monthly values of the candidates
[~, i_srt] = sort(FS,2,'ascend'); % Sort each month along all years
i_srt = i_srt(:,1:num_cand); % Select the first number of candidates

candidates.years = years(i_srt);
for m = 1:12
    values(m,:) = DNI_m(m,i_srt(m,:));
end
candidates.values = values;

end
