function [ outFR ] = ...
    tmyFR( data_day_DNI, DNI_m, DNI_mf, nbins, fileOut )
%TMYDRY Selects the TMM according to the Festa-Ratto method. Writes down a 
%corresponding report and print graphs.
%   INPUT:
%   data_day_DNI: Input daily DNI series (n days X [YYYY MM DD DNI_values])
%   DNI_m = DNI monthly values (12 rows X n years columns)
%   DNI_mf: Monthly DNI validation flag of each month
%   fileOut: Name of the output report with the results of the methodology
%
%   OUTPUT:
%   outFR: Results of the selected TMM with the Festa-Ratto method
%       1st column: Selected year of the TMM
%       2nd column: Monthly value of the selected TMM
%
% - F. Mendoza (June 2017) Update

year_ini = data_day_DNI(1,1); % Initial year
year_end = data_day_DNI(end,1); % Final year
n_years = year_end-year_ini+1; % Number of years
years = year_ini:year_end; % Years analyzed
% DRY pre-allocation
Year_selFR = zeros(12,1); % Selected year TMM
Val_selFR = zeros(12,1); % DNI monthly value TMM

%% Standarized residuals (X)
% F-R (Festa-Ratto method) METHODOLOGY ------------------------------------
days_y_DNI = reshape(data_day_DNI(:,4),365,n_years); % Daily DNI (365Xn_years)
LTDM_DNI = NaN(365,1); % Pre-allocate long term daily mean
LTDstd_DNI = NaN(365,1); % Pre-allocate long term daily mean

for d = 1:365 % Long-term daily mean and std dev
    LTDM_DNI(d) = mean(days_y_DNI(d,~isnan(days_y_DNI(d,:))));
    LTDstd_DNI(d) = std(days_y_DNI(d,~isnan(days_y_DNI(d,:))));
end

smooth_LTDM_DNI = smoothed(LTDM_DNI); % Smoothed LTDM
smooth_LTDstd_DNI = smoothed(LTDstd_DNI); % Smoothed LTDM

X = (days_y_DNI-smooth_LTDM_DNI)./smooth_LTDstd_DNI; % Daily standarized residuals (365Xn_years)

%% First order products (z) and standardized residual (Z)
X1 = [X(2:end,:); X(1,:)];
X1(isnan(X1)) = 1; % NaN are replaced by '1' in order to avoid loss of information
z = X.*X1;

LTDM_z = NaN(365,1); % Pre-allocate long term daily mean z
LTDstd_z = NaN(365,1); % Pre-allocate long term daily mean z
for d = 1:365 % Long-term daily mean and std dev z
    LTDM_z(d) = mean(z(d,~isnan(z(d,:))));
    LTDstd_z(d) = std(z(d,~isnan(z(d,:))));
end

smooth_LTDM_z = smoothed(LTDM_z); % Smoothed LTDM
smooth_LTDstd_z = smoothed(LTDstd_z); % Smoothed LTDM

Z = (z-smooth_LTDM_z)./smooth_LTDstd_z; % Daily standarized residuals (365Xn_years)

%% Monthly long-term (each month along all years) (X & Z)
Xc = reshape(X,[],1); % X reshaped into a single column
Zc = reshape(Z,[],1); % Z reshaped into a single column
maxX = max(Xc); % Maximum X along all years
maxZ = max(Zc); % Maximum Z along all years
minX = min(Xc); % Minimum X along all years
minZ = min(Zc); % Minimum Z along all years

% Monthly long-term CDF (each month along all years)
% Pre-allocating
CDFLTX_num = NaN(12,2+nbins); % Array to save the cumulative number of each bin along all years
CDFLTX_cumpct = NaN(12,2+nbins); % Array to save the cumulative percent of each bin along all years
CDFLTZ_num = NaN(12,2+nbins); % Array to save the cumulative number of each bin along all years
CDFLTZ_cumpct = NaN(12,2+nbins); % Array to save the cumulative percent of each bin along all years
LTMX = NaN(12,1); % Average daily X of each month along all years
LTMZ = NaN(12,1); % Average daily Z of each month along all years
LTstdX = NaN(12,1); % Std dev daily X of each month along all years
LTstdZ = NaN(12,1); % Std dev daily Z of each month along all years

for m = 1:12      
    pos_m = data_day_DNI(:,2)==m;
    % Removing positions of the bad years
    bad_years = find(DNI_mf(m,:)~=1);
    bad_years = bad_years+year_ini-1; % Get the number of the years which months aren't valid
    if any(bad_years)
        for bad = 1:length(bad_years)
            pos_bad = (data_day_DNI(:,2)==m & data_day_DNI(:,1)==bad_years(bad));
            pos_m = xor(pos_m,pos_bad); % XOR instead of minus to keep logical index
            clear pos_bad
        end
    end
    
    LTMX(m) = mean(Xc(pos_m)); % 
    LTMZ(m) = mean(Zc(pos_m)); % 
    LTstdX(m) = std(Xc(pos_m)); % 
    LTstdZ(m) = std(Zc(pos_m)); % 
    
    % CDFLTX_num(m,1) = 0; CDFLTZ_num(m,1) = 0;
    CDFLTX_num(m,2) = m; CDFLTZ_num(m,2) = m;
    % CDFLTX_cumpct(m,1) = 0; CDFLTZ_cumpct(m,1) = 0;
    CDFLTX_cumpct(m,2) = m; CDFLTZ_cumpct(m,2) = m;
    
    [CDFLTX_num(m,3:end), CDFLTX_cumpct(m,3:end)] = CDF_general(Xc(pos_m),maxX,minX,nbins); % Function
    [CDFLTZ_num(m,3:end), CDFLTZ_cumpct(m,3:end)] = CDF_general(Zc(pos_m),maxZ,minZ,nbins); % Function
end

%% Monthly short-term (X & Z)
% Pre-allocating
row = 0;
CDFXym_num = NaN(n_years*12,2+nbins); % Array to save the cumulative number of days of each bin per month
CDFXym_cumpct = NaN(n_years*12,2+nbins); % Array to save the cumulative percent of each bin per month
CDFZym_num = NaN(n_years*12,2+nbins); % Array to save the cumulative number of days of each bin per month
CDFZym_cumpct = NaN(n_years*12,2+nbins); % Array to save the cumulative percent of each bin per month
MX = NaN(12,n_years); % Average daily X of each month along all years
MZ = NaN(12,n_years); % Average daily Z of each month along all years
stdX = NaN(12,n_years); % Std dev daily X of each month along all years
stdZ = NaN(12,n_years); % Std dev daily Z of each month along all years

for y = years
    for m = 1:12
        i_y = y-year_ini+1;
        pos_m = (data_day_DNI(:,1)==y & data_day_DNI(:,2)==m);
        row = row+1;
        CDFXym_num(row,1) = y; CDFZym_num(row,1) = y;
        CDFXym_num(row,2) = m; CDFZym_num(row,2) = m;
        CDFXym_cumpct(row,1) = y; CDFZym_cumpct(row,1) = y;
        CDFXym_cumpct(row,2) = m; CDFZym_cumpct(row,2) = m;
        if DNI_mf(m,i_y)==1 % Flag monthly validation !!! Good month
            MX(m,i_y) = mean(Xc(pos_m)); %
            MZ(m,i_y) = mean(Zc(pos_m)); %
            stdX(m,i_y) = std(Xc(pos_m)); %
            stdZ(m,i_y) = std(Zc(pos_m)); %
            [CDFXym_num(row,3:end), CDFXym_cumpct(row,3:end)] = CDF_general(Xc(pos_m),maxX,minX,nbins); % Function
            [CDFZym_num(row,3:end), CDFZym_cumpct(row,3:end)] = CDF_general(Zc(pos_m),maxZ,minZ,nbins); % Function
        end
    end
end

%% Distance calculation (X & Z)
davXym = abs(MX-LTMX);
davZym = abs(MZ-LTMZ);
dsdXym = abs(stdX-LTstdX);
dsdZym = abs(stdZ-LTstdZ);

% Kolmogorov-Smirnov (KS) statistic ---------------------------------------
% Pre-allocation
absDiffX_y = zeros(12,nbins,n_years); % Absolute difference between the long-term CDF and each month CDF (sheet per year)
absDiffZ_y = zeros(12,nbins,n_years); % Absolute difference between the long-term CDF and each month CDF (sheet per year)
dksX_y = zeros(12,1,n_years); % FS statistic (sheet per year)
dksZ_y = zeros(12,1,n_years); % FS statistic (sheet per year)

spreadsheetX = reshape(CDFXym_cumpct(:,3:end)',nbins,12,[]); % Reshape per Bins X Months X Years
spreadsheetZ = reshape(CDFZym_cumpct(:,3:end)',nbins,12,[]); % Reshape per Bins X Months X Years
for i = 1:n_years
    sheetX_y = spreadsheetX(:,:,i)';
    absDiffX_y(:,:,i) = abs(sheetX_y-CDFLTX_cumpct(:,3:end));
    dksX_y(:,:,i) = max(absDiffX_y(:,:,i),[],2);
    
    sheetZ_y = spreadsheetZ(:,:,i)';
    absDiffZ_y(:,:,i) = abs(sheetZ_y-CDFLTZ_cumpct(:,3:end));
    dksZ_y(:,:,i) = max(absDiffZ_y(:,:,i),[],2);
end

dksXym = reshape(dksX_y,12,n_years); % Reshape (Months X Years)
dksZym = reshape(dksZ_y,12,n_years); % Reshape (Months X Years)

% Weighted average distances
alpha = 0.1; beta = alpha;
dXym = (1-alpha-beta)*dksXym+alpha*davXym+beta*dsdXym;
dZym = (1-alpha-beta)*dksZym+alpha*davZym+beta*dsdZym;

%% Selection TMM
dmax_ym = max(dXym,dZym); % Assign the maximum (worse) to each month
[dminmax_selFR, i_selFR] = min(dmax_ym,[],2); % Selected the the month with the best (minimum) distance
CDFX_selFR_cumpct = zeros(12,2+nbins);
CDFZ_selFR_cumpct = zeros(12,2+nbins);

for m = 1:12 % Get selected year/month and its value
    Year_selFR(m) = years(i_selFR(m));
    Val_selFR(m) = DNI_m(m,i_selFR(m));
    posTMM = CDFXym_cumpct(:,1)==Year_selFR(m) & CDFXym_cumpct(:,2)==m;
    CDFX_selFR_cumpct(m,1) = Year_selFR(m); CDFZ_selFR_cumpct(m,1) = Year_selFR(m);
    CDFX_selFR_cumpct(m,2) = m; CDFZ_selFR_cumpct(m,2) = m;
    CDFX_selFR_cumpct(m,3:end) = CDFXym_cumpct(posTMM,3:end); % TMM selected
    CDFX_selFR_cumpct(m,3:end) = CDFZym_cumpct(posTMM,3:end); % TMM selected
end

%% FR (Festa-Ratto method) TMY METHODOLOGY output report
% Standarized residuals report (X) ----------------------------------------
headerY = year_ini:year_end;
X_ex = [['Month', 'Day', num2cell(headerY)]; num2cell([data_day_DNI(1:365,2:3), round(X,2)])];
xlswrite(fileOut,X_ex,'X','A1'); % Write the headers & results

% Standarized residuals report (Z) ----------------------------------------
Z_ex = [['Month', 'Day', num2cell(headerY)]; num2cell([data_day_DNI(1:365,2:3), round(Z,2)])];
xlswrite(fileOut,Z_ex,'Z','A1'); % Write the headers & results

% LT CDF (X and Z) report -------------------------------------------------
headers = cell(1,2+nbins);
headers{1} = '----'; headers{2} = 'Month';
for i = 1:nbins
    headers{i+2} = ['Bin ' num2str(i)];
end

xlswrite(fileOut,[headers; num2cell(floor(CDFLTX_cumpct*100)/100)],'CDFLT_X','A1'); % Write LT CDF X
xlswrite(fileOut,[headers; num2cell(floor(CDFLTZ_cumpct*100)/100)],'CDFLT_Z','A1'); % Write LT CDF Z

% Individual months CDF report --------------------------------------------
headers{1} = 'Year';
xlswrite(fileOut,[headers; num2cell(floor(CDFXym_cumpct*100)/100)],'CDF_X_ym','A1'); % Write CDF per year
xlswrite(fileOut,[headers; num2cell(floor(CDFZym_cumpct*100)/100)],'CDF_Z_ym','A1'); % Write CDF per year

% Weighted average distances (X and Z) report -----------------------------
headers_m = {'Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';'Aug';'Sep';'Oct';'Nov';'Dic'}; % Headers months
dXym_ex = [num2cell([NaN years]); [headers_m, num2cell(round(dXym,2))]];
xlswrite(fileOut,dXym_ex,'dX_ym','A1'); % Write the dX_ym of each month

dZym_ex = [num2cell([NaN years]); [headers_m, num2cell(round(dZym,2))]];
xlswrite(fileOut,dZym_ex,'dZ_ym','A1'); % Write the dZ_ym of each month

% Max distance report -----------------------------------------------------
dmax_ym_ex = [num2cell([NaN years]); [headers_m, num2cell(round(dmax_ym,2))]];
xlswrite(fileOut,dmax_ym_ex,'dmax_ym_ex','A1'); % Write the dX_ym of each month

% FR output ---------------------------------------------------------
outFR(:,1) = Year_selFR; % 1st column: Selected year of the TMM
outFR(:,2) = Val_selFR; % 2nd column: Monthly value of the selected TMM
outFR(:,3) = round(dminmax_selFR,4); % 3rd column: Distance of the selected TMM
FR_ex = [{'', 'Year', 'RMV IEC1/F-R (kWh/m2)', 'Distance (dminmax)'}; [headers_m, num2cell(outFR)]];
xlswrite(fileOut,FR_ex,'outputF-R','A1');

%% Figures
% Long Term Daily Mean & Std Dev, smooth (X) ------------------------------
period = (datetime([year_end-9 1 1 0 0 0]):day(1):datetime([year_end 12 31 23 59 0]))'; % The last 10 years are selected because has less missing records
for i = 1:length(period)
    temp = datevec(period(i));
    if temp(2)==2 && temp(3)==29
        period(i)=NaT;
    end
end
period(isnat(period))=[];
start = length(data_day_DNI(:,4))-10*365+1;
fileName = [fileOut(1:end-8) 'X-FR'];

figure;
ax1 = subplot(2,2,1);
plot(period,data_day_DNI(start:end,4))
title(ax1,'Raw values')
ylabel(ax1,'Daily DNI (Wh/m2)')

ax2 = subplot(2,2,3);
plot(period,Xc(start:end))
title(ax2,'Standarized daily DNI residuals')
ylabel(ax2,'X'); xlabel(ax2,'Years')

x = 1:365;
ax3 = subplot(2,2,2);
plot(x,LTDM_DNI,x,LTDstd_DNI)
title(ax3,'Long-term daily mean and std. deviation')
legend({'Mean', 'Std. dev.'},'Location','NorthEast');
xlim([1 x(end)]); ylabel(ax3,'DNI (Wh/m2)')

ax4 = subplot(2,2,4);
plot(x,smooth_LTDM_DNI,x,smooth_LTDstd_DNI);
title(ax4,'Smoothed long-term')
legend({'Mean', 'Std. dev.'},'Location','NorthEast');
xlim([1 365]); ylabel(ax4,'DNI (Wh/m2)')
xlabel(ax4,'Days')
print('-djpeg','-opengl','-r350',fileName)

% Z -----------------------------------------------------------------------
figure; plot(period,Zc(start:end))
title('Standarized z residuals')
ylabel('Z'); xlabel('Years'); fileName = [fileOut(1:end-8) 'Z-FR'];
print('-djpeg','-opengl','-r350',fileName)

% Long Term CDF -----------------------------------------------------------
figCDFLTX = CDFLTX_cumpct(:,3:end);
titleFig = 'Long-term CDF X'; fileName = [fileOut(1:end-8) 'CDFLTX-FR'];
plotCDF3D(figCDFLTX,titleFig,fileName)

figCDFLTZ = CDFLTZ_cumpct(:,3:end);
titleFig = 'Long-term CDF Z'; fileName = [fileOut(1:end-8) 'CDFLTZ-FR'];
plotCDF3D(figCDFLTZ,titleFig,fileName)

% CDF TMY selected --------------------------------------------------------
figCDFXFR = CDFX_selFR_cumpct(:,3:end);
titleFig = 'CDF X FR selected'; fileName = [fileOut(1:end-8) 'CDFXTMM-FR'];
plotCDF3D(figCDFXFR,titleFig,fileName)

figCDFZFR = CDFX_selFR_cumpct(:,3:end);
titleFig = 'CDF Z FR selected'; fileName = [fileOut(1:end-8) 'CDFZTMM-FR'];
plotCDF3D(figCDFZFR,titleFig,fileName)

end
