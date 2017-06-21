%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% MODULE 5: ANNUAL SOLAR RADIATION SERIES GENERATION
% Version of July, 2015. L. Ramírez; At CSIRO.
% Update F. Mendoza (June 2017) at CIEMAT.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT:
% ..\OUTPUT\4_TMYMETH
%       'loc00-owner_station-num'-IN_SERIESGEN.xlsx
% ..\OUTPUT\3_VALIDATION
%       'dataval' structure of the selected years (i.e. loc00-owner_station-num-YYYY_VAL)
%
% OUTPUT:
% ..\OUTPUT\5_ASR\NAME_SERIES
%  (1) Excel report 'loc00-owner_station-num'_SERIES Sheets:
%       - 'name_series'_D: Definitive daily radiation series of the typical year
%       - 'name_series'_M: Definitive monthly radiation series of the typical year
%  (2) Plain text formats
%  (2a) SAM CSV format 'SAM_...'.csv
%  (2b) IEC 62862-1-3 format 'ASR_...'.txt
%  (3) Figures: Plot of the definitive series
%  (4) out_series.mat: Saves the definitive series, daily and monthly of
%      the typical year
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close, clearvars -except cfgFile, %clc
run(cfgFile); % Run configuration file

if ~exist(path_asr,'dir')
    mkdir(path_asr);
end

namef = [loc '00-' owner_station '-' num]; % MATLAB files with the results of the validation process
filename_val = strcat(path_val,'\',namef,'_VAL','.xlsx'); % Validation Excel report
filename_input = strcat(path_meth,'\',namef,'-IN_SERIESGEN.xlsx'); % Input Generation
num_previous_days = [0 cumsum(num_days_m(1:length(num_days_m)-1))]; % Number of days previous to the month start

%% Reading data of the input series generation file
[~,variable] = xlsread(filename_input,'VARIABLE','A1'); % Read main variable

switch variable{1}
    case 'GHI'
        col_main_m = 7; % Each year, in Validation data structure
        cols_main_m = 1:3; % Each year, in Excel file (Validation Report)
    case 'DNI'
        col_main_m = 9; % Each year, in Validation data structure
        cols_main_m = 4:6; % Each year, in Excel file (Validation Report)
    otherwise
        warning(strcat('The main variable is not identificable in Excel file ',...
            filename_input,' within the sheet VARIABLE.'))
end

% Read the years of the selected months to be concatenated and the name of the series
[series_in,text_series_in,~] = xlsread(filename_input,'INPUT');
% Read objective data for series generation
RMV = xlsread(filename_input,'OBJECTIVE'); % Representative long term monthly value (Objective value). One column per series.
ARV = sum(RMV); % Annual Representative Value (so many columns as series)
n_series = size(series_in,2); % Number of columns/series to generate

%% Reading data of the validation process results
% Read daily validation process results
[days_y_val, text_val] = xlsread(filename_val,'Val_day');
days_y_val(:,1) = []; % Delete month column
year_ini = str2double(text_val{1,2}(1:4)); year_end = str2double(text_val{1,end}(1:4));
years_val = year_ini:year_end; % Years included in the validation process
% Read monthly validation process results
month_y_val = xlsread(filename_val,'Val_Month');

%% Loops through Series and Months
% Pre-allocation output vars
colS = 16; SERIES_out = NaN(365*24*num_obs,colS,n_series); % Array with the definitive series. colS maximum number of variables including other meteo
colD = 6; DAYS_out = NaN(365,colD,n_series); % Array with the definitive daily series
colM = 6; MONTHS_out = NaN(12,colM,n_series); % Array with the definitive monthly series
cosz_out = NaN(365*24*num_obs,1); % Save cosine of zenith angle in case of interpolation
SERIES_out_int = SERIES_out; % Interpolated series (for variables not included in the validation)
name_series = cell(1,n_series);
addVars = 4; otherMeteo = cell(12,addVars,n_series); % Save which additional meteorological variables are included with the data

for i=1:n_series
    nameSerie = text_series_in{1,i+1}; % Creation path for results
    nameSerie(nameSerie=='/') = '-'; % Replace '/' by '-' for path creation
    name_series{i} = nameSerie;
    path_series = strcat(path_asr,'\',name_series{i});
    if ~exist(path_series,'dir')
        mkdir(path_series);
    end
    
    path_fig = strcat(path_series,'\','figures'); % Creation path for figures
    if ~exist(path_fig,'dir')
        mkdir(path_fig);
    end
    
    fprintf('\nGenerating the %s series for simulation.\n',name_series{i});
    MV = zeros(12,1); % To save monthly value
    
    for m = 1:12 % Extraction of the series, daiily and monthly values
        year = series_in(m,i); % Get the number of the year to read the corresponding data
        
        % Get the series data ---------------------------------------------
        % Structure with the validated data (Interpolation and Substitution done)
        load(strcat(path_val,'\',namef,'-',num2str(year),'_VAL'));
        num_obs = dataval.timedata.num_obs;
        
        % Rows of the month according with the number of observations
        row_m_obs_ini = num_previous_days(m)*24*num_obs+1; % Remember, after validation all years have 365 days
        row_m_obs_end = row_m_obs_ini+(num_days_m(m)*24*num_obs)-1;
        
        series_m = dataval.mqc(row_m_obs_ini:row_m_obs_end,:);
        cosz_m = dataval.astro(row_m_obs_ini:row_m_obs_end,8); % Cosine of the solar zenith angle
        
        % Get the daily data ----------------------------------------------
        n_year = find(years_val==year); % Position of the year
        % Columns of the year selected
        col_y_ini = 1+colD*(n_year-1);
        col_y_end = col_y_ini+5;
        % Rows of the month according with the number of days
        row_m_d_ini = num_previous_days(m)+1; % Remember, after validation all years have 365 days
        row_m_d_end = row_m_d_ini+num_days_m(m)-1;
        
        days_m_val = days_y_val(row_m_d_ini:row_m_d_end,col_y_ini:col_y_end); % Get data
        
        % Get the monthly data --------------------------------------------
        month_val = month_y_val(m,col_y_ini:col_y_end); % Get data
        
        % Verification of values coherence --------------------------------
        % Check if all data is a valid number
        i_data = ~isnan(series_m(:,col_main_m)) & series_m(:,col_main_m)~=-999;
        if sum(i_data)~=size(series_m,1)
            warning('Some non-identifiable data are in the final series of the main variable.\n Please verify (NaN or -999) in the year %d and month %d.',...
                year,m)
        end
        
        % Monthly value from the monthly validation Excel report
        MV(m) = month_val(1,cols_main_m(2));
        % Monthly value is equal to the sum of the series values after validation
        series_MV = round(sum(series_m(i_data,col_main_m))/(num_obs*1000)); % kWh/m2
        if series_MV~=MV(m)
            warning('The sum up of the series radiation data of the year %d and month %d\n do not correspond with the monthly value of the candidate month.',...
                year,m)
        end
        
        % Monthly value is equal to the sum of the series daily values
        daily_MV = round(sum(days_m_val(:,cols_main_m(2)))/1000); % kWh/m2
        if daily_MV~=MV(m)
            warning('The sum up of the daily radiation data of the year %d and month %d\n do not correspond with the monthly value of the candidate month.',...
                year,m)
        end
        % If no warnings: All values are coherent
        
        % Check difference between monthly irradiance value and RMV -------
        % Equation (6) Standard IEC 62862-1-2
        limit = (ARV(i)/12)*0.02; % Limit of the difference between monthly value and RMV
        if abs(RMV(m,i)-MV(m)) >= limit
            days_m = [days_m_val(:,1) days_m_val(:,cols_main_m(2))/1000]; % # of day and daily irradiance in kWh/m2
            if MV(m) <= RMV(m,i) % Monthly value must increment
                [resultSubs,substituted,used,counter,ctrl,warn]...
                    = subs_days_up(m,days_m,RMV(m,i),limit,max_dist,max_times,max_subs); % Function
            elseif MV(m) > RMV(m,i) % Monthly value must decrement
                [resultSubs,substituted,used,counter,ctrl,warn]...
                    = subs_days_dw(m,days_m,RMV(m,i),limit,max_dist,max_times,max_subs); % Function
            end
            if warn
                fprintf('Year: %d, Month: %d\n',year,m);
            end
        else % No substitutions are carried out
            resultSubs = NaN; substituted = NaN; used = NaN;
            counter = NaN; ctrl = NaN;
        end
        finalSubs.result{i,m} = resultSubs;
        finalSubs.substituted{i,m} = substituted;
        finalSubs.used{i,m} = used;
        finalSubs.counter{i,m} = counter;
        finalSubs.ctrl{i,m} = ctrl;
        
        % Apply the last substitutions ------------------------------------
        if ~isnan(resultSubs)
            subs_days = (1:num_days_m(m))'.*substituted; % Index of the substituted days
            subs_days(subs_days==0) = []; % Trim zeros
            final_days = resultSubs(:,end-1); % Final days after substitutions
            origin_days = final_days(substituted); % Origin day for each substitution
            for k = 1:size(subs_days,1)
                if days_m_val(subs_days(k),1)~=days_m_val(origin_days(k),4) % Substitution did not make yet
                    lin_ini_orig = (origin_days(k)-1)*24*num_obs+1;
                    lin_end_orig = origin_days(k)*24*num_obs;
                    lin_ini_subs = (subs_days(k)-1)*24*num_obs+1;
                    lin_end_subs = subs_days(k)*24*num_obs;
                    
                    series_m(lin_ini_subs:lin_end_subs,1:12) = series_m(lin_ini_orig:lin_end_orig,1:12); % Update series of the month
                    days_m_val(subs_days(k),:) = days_m_val(origin_days(k),:); % Update daily series of the month
                end
            end
            month_val(1,[2,5]) = round([sum(days_m_val(:,2)) sum(days_m_val(:,5))]/1000); % Update month irradiance values
            month_val(1,[3,6]) = 2; % Update monthly validation flags !!! 2?
        end
        
        % Output Series ---------------------------------------------------
        SERIES_out(row_m_obs_ini:row_m_obs_end,1:size(series_m,2),i) = series_m;
        DAYS_out(row_m_d_ini:row_m_d_end,:,i) = days_m_val;
        MONTHS_out(m,:,i) = month_val;
        cosz_out(row_m_obs_ini:row_m_obs_end) = cosz_m;
        
        % Save which additional meteorological variables are included with the data
        addMeteo = length(dataval.header)-9;
        if addMeteo~=0
            otherMeteo(m,1:addMeteo,i) = dataval.header(10:end);
        end
    end
    
    %% Calculation or Interpolation of the other variables
    % Variables not inclued in the validation process are interpolated
    [SERIES_out_int(:,1:12,i),num_cases] = interpolating_holes(SERIES_out(:,1:12,i),cosz_out,num_obs); % Function
    fprintf('Final interpolation results of the %s series\n',name_series{i});
    fprintf('# of GHI data calculated from the other variables: %d\n',num_cases(1));
    fprintf('# of DNI data calculated from the other variables: %d\n',num_cases(2));
    fprintf('# of DHI data calculated from the other variables: %d\n',num_cases(3));
    fprintf('# of DNI data interpolated and GHI calculated: %d\n',num_cases(4));
    fprintf('# of DNI data interpolated and DHI calculated: %d\n',num_cases(5));
    fprintf('# of GHI data interpolated and DHI calculated: %d\n',num_cases(6));
    fprintf('# of GHI, DNI data interpolated and DHI calculated: %d\n',num_cases(7));
    SERIES_out_int(:,13:end,i) = SERIES_out(:,13:end,i); % Add other meteo vars
        
    %% Write down EXCEL series report
    filename_out = strcat(path_series,'\',namef,'_',name_series{i},'.xlsx'); % Output Generation
    fprintf('Generating EXCEL report for %s series\n',name_series{i});
    
    % Switch off new excel sheet warning
    warning off MATLAB:xlswrite:AddSheet

    % Write the definitive daily series of the typical year ---------------
    headerD{1} = 'Year'; headerD{2} = 'Month';
    headerD{3} = 'day GHI'; headerD{4} = 'GHI (Wh/m2)'; headerD{5} = 'fdvGHI';
    headerD{6} = 'day DNI'; headerD{7} = 'DNI (Wh/m2)'; headerD{8} = 'fdvDNI';
    headerD{9} = 'Substituted';
    
    % Year and month for daily results
    year_y = zeros(365,1); year_m = zeros(365,1); k = 1; % No leap years
    substituted_ex = false(365,1);
    for month = 1:12
        row_m_d_ini = num_previous_days(month)+1;
        row_m_d_end = row_m_d_ini+num_days_m(month)-1;
        if ~isnan(finalSubs.substituted{i,month}) % If susbstitutions were carried out in this module
            substituted_ex(row_m_d_ini:row_m_d_end) = finalSubs.substituted{i,month};
        end
        for d = 1:num_days_m(month)
            year_y(k) = series_in(month,i);
            year_m(k) = month;
            k = k+1;
        end
    end
    
    day_ex = num2cell([year_y year_m DAYS_out(:,:,i) substituted_ex]);
    xlswrite(filename_out,[headerD; day_ex],strcat(name_series{i},'_D'),'A1');
        
    % Write the definitive monthly series of the typical year -------------
    headerM{1} = 'Year';
    headerM{2} = 'month'; headerM{3} = 'GHI (kWh/m2)'; headerM{4} = 'fmvGHI';
    headerM{5} = 'month'; headerM{6} = 'DNI (kWh/m2)'; headerM{7} = 'fmvDNI';
    headerM{8} = [variable{1} ' RMV']; headerM{9} = ['Initial ' variable{1}];
    headerM{10} = 'Substitutions';
    
    subs_ex = cell2mat(finalSubs.counter(i,:))'; % For Excel report
    month_ex = num2cell([series_in(:,i) MONTHS_out(:,:,i) RMV(:,i) MV subs_ex]);
    xlswrite(filename_out,[headerM; month_ex],strcat(name_series{i},'_M'),'A1');
    
    %% Plot figures
    % Plotting solar radiation outputs
    figure;
    plot(SERIES_out_int(:,7,i) ,'-b') % Definitive GHI series -------------
    axis([1 365*24*num_obs 0 1600]); grid on;
    title([name_series{i},' - GHI'],'Fontsize',16);
    xlabel('Observations','Fontsize',16);
    ylabel('W/m^2','Fontsize',16);
    filename = strcat(name_series{i},'-GHI');
    print('-djpeg','-opengl','-r350',strcat(path_fig,'\',filename))
    
    figure;
    plot(SERIES_out_int(:,9,i) ,'-r') % Definitive DNI series -------------
    axis([1 365*24*num_obs 0 1600]); grid on;
    title([name_series{i},' - DNI'],'Fontsize',16);
    xlabel('Observations','Fontsize',16);
    ylabel('W/m^2','Fontsize',16);
    filename = strcat(name_series{i},'-DNI');
    print('-djpeg','-opengl','-r350',strcat(path_fig,'\',filename))
    
    figure;
    plot(SERIES_out_int(:,11,i),'-c') % Definitive DHI series -------------
    axis([1 365*24*num_obs 0 1000]); grid on;
    title([name_series{i},' - DHI'],'Fontsize',16);
    xlabel('Observations','Fontsize',16);
    ylabel('W/m^2','Fontsize',16);
    filename = strcat(name_series{i},'-DHI');
    print('-djpeg','-opengl','-r350',strcat(path_fig,'\',filename))
    close all
    
    % Daily figures - Are you sure you want to do this? -------------------
%     numD = 0;
%     for month = 1:12
%         for day = 1:num_days_m(month)
%             numD = numD+1;
%             first = (numD-1)*24*num_obs+1;
%             last = numD*24*num_obs;
%             
%             day_piece = SERIES_out_int(first:last,:,i);
%             
%             year_str = num2str(day_piece(1,1));
%             month_str = num2str(month);
%             day_str = num2str(day);
%             
%             G0 = dataval.astro(first:last,9); % Extraterrestrial solar radiation (W/m2)
%             hour = day_piece(:,4);
%             min = day_piece(:,5);
%             hourdec = hour+min/60;
%             GHI = day_piece(:,7);
%             DNI = day_piece(:,9);
%             DHI = day_piece(:,11);
%             
%             date_str = ['Month ' month_str ' - Day ' day_str ' - Year ' year_str];
%             
%             figure;
%             plot(hourdec,G0,'-k'); hold on
%             plot(hourdec,GHI,'b-o');
%             plot(hourdec,DNI,'r-o');
%             plot(hourdec,DHI,'c-o');
%             axis([0 24 0 1600]);
%             grid on
%             title([name_series{i},' - ',date_str],'Fontsize',16);
%             xlabel('Local Universal Time','Fontsize',16);
%             ylabel('W/m^2','Fontsize',16);
%             leg = legend('G0','GHI','DNI','DHI');
%             set(leg,'Fontsize',16);
%             filename = strcat(name_series{i},'-',date_str);
%             print('-djpeg','-opengl','-r350',strcat(path_fig,'\',filename))
%             close all
%         end
%     end
    
end

save(strcat(path_asr,'\','out_series'),'name_series','series_in','SERIES_out_int',...
    'DAYS_out','MONTHS_out','finalSubs','otherMeteo'); % Save results
