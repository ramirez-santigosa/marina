function [ outDRY ] = ...
    tmyDRY( data_day_DNI, data_day_GHI, DNI_m, DNI_mf, fileOut )
%TMYDRY Selects the TMM according to the Danish method (Design Reference
%Years). Writes down a corresponding report and print graphs.
%   INPUT:
%   data_day_DNI: Input daily DNI series (n days X [YYYY MM DD DNI_values])
%   data_day_GHI: Input daily GHI series (n days X [YYYY MM DD GHI_values])
%   DNI_m = DNI monthly values (12 rows X n years columns)
%   DNI_mf: Monthly DNI validation flag of each month
%   fileOut: Name of the output report with the results of the methodology
%
%   OUTPUT:
%   outDRY: Results of the selected TMM with the Danish method
%       1st column: Selected year of the TMM
%       2nd column: Monthly value of the selected TMM
%
% - F. Mendoza (June 2017) Update

year_ini = data_day_DNI(1,1); % Initial year
year_end = data_day_DNI(end,1); % Final year
n_years = year_end-year_ini+1; % Number of years
years = year_ini:year_end; % Years analyzed
% DRY pre-allocation
Year_selDRY = zeros(12,1); % Selected year TMM
Val_selDRY = zeros(12,1); % DNI monthly value TMM

%% Climatological qualification (Criterion A)
% Pre-allocating
MdM_DNI = NaN(12,n_years); % Short term (each month) mean daily DNI 
MdM_GHI = NaN(12,n_years); % Short term (each month) mean daily GHI
LTMdM_DNI = NaN(12,1); % Long term monthly mean daily DNI
LTMdM_GHI = NaN(12,1); % Long term monthly mean daily GHI
LTMdstd_DNI = NaN(12,1); % Standard deviation monthly mean daily DNI
LTMdstd_GHI = NaN(12,1); % Standard deviation monthly mean daily GHI
score_DNI = NaN(12,n_years); % DNI score of each month
score_GHI = NaN(12,n_years); % GHI score of each month

for y = year_ini:year_end % Calculate short-term mean
    for m = 1:12
        i_y = y-year_ini+1;
        if DNI_mf(m,i_y)==1 % Flag monthly validation !!! Good month
            pos_m = (data_day_DNI(:,1)==y & data_day_DNI(:,2)==m);
            MdM_DNI(m,i_y) = mean(data_day_DNI(pos_m,4));
            MdM_GHI(m,i_y) = mean(data_day_GHI(pos_m,4));
        end
    end
end

for m = 1:12 % Calculate long-term and scores
    LTMdM_DNI(m) = mean(MdM_DNI(m,~isnan(MdM_DNI(m,:))));
    LTMdM_GHI(m) = mean(MdM_GHI(m,~isnan(MdM_GHI(m,:))));
    LTMdstd_DNI(m) = std(MdM_DNI(m,~isnan(MdM_DNI(m,:))));
    LTMdstd_GHI(m) = std(MdM_GHI(m,~isnan(MdM_GHI(m,:))));
    score_DNI(m,:) = abs(MdM_DNI(m,:)-LTMdM_DNI(m))<=LTMdstd_DNI(m);
    score_GHI(m,:) = abs(MdM_GHI(m,:)-LTMdM_GHI(m))<=LTMdstd_GHI(m);
end

score = score_DNI+score_GHI; % Score of each month

%% Criteria B and C 
% DRY (Danish method) METHODOLOGY -----------------------------------------
% Mathematical selection
days_y_DNI = reshape(data_day_DNI(:,4),365,n_years); % Daily DNI (365Xn_years)
LTDM_DNI = NaN(365,1); % Pre-allocate long term daily mean

for d = 1:365 % Long-term daily mean
    LTDM_DNI(d) = mean(days_y_DNI(d,~isnan(days_y_DNI(d,:))));
end

smooth_LTDM_DNI = smoothed(LTDM_DNI); % Smoothed LTDM

Y = days_y_DNI-smooth_LTDM_DNI; % Daily residuals (365Xn_years)

mu_Y = NaN(12,n_years); % Mean daily residuals (Monthly mean)
sigma_Y = NaN(12,n_years); % Std dev daily residuals
for i_y = 1:n_years
    for m = 1:12
        if DNI_mf(m,i_y)==1 % Flag monthly validation !!! Good month
            pos_m = (data_day_DNI(1:365,2)==m);
            mu_Y(m,i_y) = mean(Y(pos_m,i_y));
            sigma_Y(m,i_y) = std(Y(pos_m,i_y));
        end
    end
end

mu_mu_Y = NaN(1,n_years); sigma_mu_Y = NaN(1,n_years);
mu_sigma_Y = NaN(1,n_years); sigma_sigma_Y = NaN(1,n_years);
for i_y = 1:n_years % Means and std dev per year
    mu_mu_Y(i_y) = mean(mu_Y(~isnan(mu_Y(:,i_y)),i_y));
    sigma_mu_Y(i_y) = std(mu_Y(~isnan(mu_Y(:,i_y)),i_y));
    mu_sigma_Y(i_y) = mean(sigma_Y(~isnan(sigma_Y(:,i_y)),i_y));
    sigma_sigma_Y(i_y) = std(sigma_Y(~isnan(sigma_Y(:,i_y)),i_y));
end

f_mu_ym = NaN(12,n_years); % Standardised mean
f_sigma_ym = NaN(12,n_years); % Standardised standard deviation
for i_y = 1:n_years
    for m = 1:12
        f_mu_ym(m,i_y) = abs((mu_Y(m,i_y)-mu_mu_Y(i_y))/sigma_mu_Y(i_y));
        f_sigma_ym(m,i_y) = abs((sigma_Y(m,i_y)-mu_sigma_Y(i_y))/sigma_sigma_Y(i_y));
    end
end

fmax_ym = max(f_mu_ym,f_sigma_ym); % Assign the maximum to each month
[~, i_srt] = sort(fmax_ym,2,'ascend'); % Sort each month along all years
num_cand = 3; % Number of candidates 
i_srt = i_srt(:,1:num_cand); % Select the first number of candidates
fmax_selDRY = zeros(12,1); % Save the standarized daily residual of the TMM

for m = 1:12 % Select the year with highest score (Criterion A)
    [~, i_selDRY] = max(score(m,i_srt(m,:))); % Selected year
    Year_selDRY(m) = years(i_srt(m,i_selDRY));
    Val_selDRY(m) = DNI_m(m,i_srt(m,i_selDRY));
    fmax_selDRY(m) = fmax_ym(m,i_srt(m,i_selDRY));
end

%% DRY (Danish method) TMY METHODOLOGY output report
% Score report ------------------------------------------------------------
headers_m = {'Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';'Aug';'Sep';'Oct';'Nov';'Dic'}; % Headers months
score_ex = [num2cell([NaN years]); [headers_m, num2cell(score)]];
xlswrite(fileOut,score_ex,'Score (A)','A1'); % Write the score of each month

% Daily long-term report --------------------------------------------------
headers = {'Month', 'Day', 'LTDM DNI', 'Smoothed'};
xlswrite(fileOut,[headers; num2cell([data_day_DNI(1:365,2:3),round(LTDM_DNI,2),round(smooth_LTDM_DNI,2)])],'LTDM','A1');

% Daily residuals report --------------------------------------------------
headerY = year_ini:year_end;
Y_ex = [['Month', 'Day', num2cell(headerY)]; num2cell([data_day_DNI(1:365,2:3), round(Y,2)])];
xlswrite(fileOut,Y_ex,'DailyRes (Y)','A1'); % Write the headers & results

% Standardised mean report ------------------------------------------------
f_mu_ym_ex = [num2cell([NaN years]); [headers_m, num2cell(round(f_mu_ym,2))]];
xlswrite(fileOut,f_mu_ym_ex,'StdMean','A1'); % Write the f_mu_ym of each month

% Standardised standard deviation report ----------------------------------
f_sigma_ym_ex = [num2cell([NaN years]); [headers_m, num2cell(round(f_sigma_ym,2))]];
xlswrite(fileOut,f_sigma_ym_ex,'StdStdDev','A1'); % Write the f_sigma_ym of each month

% f_max report ------------------------------------------------------------
fmax_ym_ex = [num2cell([NaN years]); [headers_m, num2cell(round(fmax_ym,2))]];
xlswrite(fileOut,fmax_ym_ex,'fmax','A1'); % Write the fmax_ym of each month

% Candidate years/month report --------------------------------------------
cand_y_ex = [num2cell([NaN 1:num_cand]); [headers_m, num2cell(years(i_srt))]];
xlswrite(fileOut,cand_y_ex,'Candidates_y','A1'); % Write the candidates years for TMM

% DRY output ---------------------------------------------------------
outDRY(:,1) = Year_selDRY; % 1st column: Selected year of the TMM
outDRY(:,2) = Val_selDRY; % 2nd column: Monthly value of the selected TMM
outDRY(:,3) = round(fmax_selDRY,4); % 3rd column: Standarized daily residual of the selected TMM
DRY_ex = [{'', 'Year', 'RMV IEC1/DRY (kWh/m2)' 'fmax (Std daily res.)'}; [headers_m, num2cell(outDRY)]];
xlswrite(fileOut,DRY_ex,'outputDRY','A1');

%% Figures
% Long Term Daily Mean & Smooth -------------------------------------------
fileName = [fileOut(1:end-5) '-LTDM'];
figure;
ax1 = subplot(2,1,1);
plot(LTDM_DNI)
title(ax1,'Long-term daily mean (LTDM)')
xlim([1 365]); ylabel(ax1,'DNI (Wh/m^2)')

ax2 = subplot(2,1,2);
plot(smooth_LTDM_DNI);
title(ax2,'Smoothed LTDM (\mu_x)')
xlim([1 365]); ylabel(ax2,'DNI (Wh/m^2)')
xlabel(ax2,'Day')
print('-dtiff','-opengl','-r350',fileName)

% Y -----------------------------------------------------------------------
Yc = reshape(Y,[],1);
period = (datetime([year_end-9 1 1 0 0 0]):day(1):datetime([year_end 12 31 23 59 0]))'; % The last 10 years are selected because has less missing records
for i = 1:length(period)
    temp = datevec(period(i));
    if temp(2)==2 && temp(3)==29
        period(i)=NaT;
    end
end
period(isnat(period))=[];
start = length(Yc)-10*365+1;
figure; plot(period,Yc(start:end))
title('Daily DNI residuals (Y)')
ylabel('Y (Wh/m^2)'); xlabel('Years'); fileName = [fileOut(1:end-5) '-Y'];
print('-dtiff','-opengl','-r350',fileName)

end
