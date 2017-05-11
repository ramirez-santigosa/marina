%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% MODULE 5: TYPICAL YEAR SERIES GENERATION
% Version of July, 2015. L. Ramírez; At CSIRO.
% Update F. Mendoza (April 2017) at CIEMAT.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT:
% ..\OUTPUT\4_CASES
%       'loc00-owner_station-num'-INPUT-GENERATION.xlsx
% ..\OUTPUT\3_VALIDATION
%       'dataval' structure of the selected years (i.e. loc00-owner_station-num-YYYY_VAL)
%
% OUTPUT:
% ..\OUTPUT\5_TMY
%  (1) Excel report 'loc00-owner_station-num'-OUTPUT-GENERATION Sheets:
%       - 'name_series'_D: Definitive daily radiation series of the typical year
%       - 'name_series'_M: Definitive monthly radiation series of the typical year
%  (2) Plain text formats
%  (2a) SAM CSV format 'SAM_...'.csv
%  (2b) IEC 62862-1-3 format 'ASR_...'.txt
%  (3) Figures: Plot of the definitive series
%  (4) output-series.mat: Saves the definitive series, daily and monthly of
%      the typical year
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close, clearvars, %clc
run('Configuration_BSRN_ASP.m');

if ~exist(path_cases,'dir')
    mkdir(path_tmy);
end

namef = [loc '00-' owner_station '-' num]; % MATLAB files with the results of the validation process
filename_val = strcat(path_val,'\',namef,'_VAL','.xlsx'); % Validation Excel report
filename_input = strcat(path_cases,'\',namef,'-INPUT-GENERATION.xlsx'); % Input Generation
num_previous_days = [0 cumsum(num_days_m(1:length(num_days_m)-1))]; % Number of days previous to the month start
if iec_format % Create a functional date vector in ISO 8601 format if IEC 62862-1-2 file will be printed
    time_func = (datetime([2015 1 1 0 0 0]):minutes(60/num_obs):...
        datetime([2015 12 31 23 60-60/num_obs 0]))'; % Functional date (IEC 62862-1-2)
    time_func_str = cellstr(datestr(time_func,'yyyy-mm-ddTHH:MM:SS')); % Functional date
end

%% Reading data of the input series generation file
[~,variable] = xlsread(filename_input,'VARIABLE','A1'); % Read main variable

switch variable{1}
    case 'GHI'
        col_main = 7; % Each year, in Validation data structure
        cols_main = 1:3; % Each year, in Excel file (Validation Report)
    case 'DNI'
        col_main = 9; % Each year, in Validation data structure
        cols_main = 4:6; % Each year, in Excel file (Validation Report)
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
year_ini = str2double(text_val{1,1}(1:4)); year_end = str2double(text_val{1,end}(1:4));
years_val = year_ini:year_end; % Years included in the validation process
% Read monthly validation process results
month_y_val = xlsread(filename_val,'Val_Month');

%% Loops through Series and Months
% Pre-allocation output vars
colS = 12; SERIES_out = NaN(365*24*num_obs,colS,n_series); % Array with the definitive series
colD = 6; DAYS_out = NaN(365,colD,n_series); % Array with the definitive daily series
colM = 6; MONTHS_out = NaN(12,colM,n_series); % Array with the definitive monthly series
cosz_out = NaN(365*24*num_obs,1); % Save cosine of zenith angle in case of interpolation
SERIES_out_int = SERIES_out; % Interpolated series (for variables not included in the validation)

for i=1:n_series
    name_series = text_series_in{1,i+1}; % Creation path for results
    path_series = strcat(path_tmy,'\',name_series);
    if ~exist(path_series,'dir')
        mkdir(path_series);
    end
    
    path_fig = strcat(path_series,'\','figures'); % Creation path for figures
    if ~exist(path_fig,'dir')
        mkdir(path_fig);
    end
    
    fprintf('Generating the %s serie for simulation.\n',name_series);
    
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
        i_data = ~isnan(series_m(:,col_main)) & series_m(:,col_main)~=-999;
        if sum(i_data)~=size(series_m,1)
            warning('Some non-identifiable data are in the final series of the main variable.\n Please verify (NaN or -999) in the year %d and month %d.',...
                year,m)
        end
        
        % Monthly value from the monthly validation Excel report
        MV = month_val(1,cols_main(2));
        % Monthly value is equal to the sum of the series values after validation
        series_MV = round(sum(series_m(i_data,col_main))/(num_obs*1000)); % kWh/m2
        if series_MV~=MV
            warning('The sum up of the series radiation data of the year %d and month %d\n do not correspond with the monthly value of the candidate month.',...
                year,m)
        end
        
        % Monthly value is equal to the sum of the series daily values
        daily_MV = round(sum(days_m_val(:,cols_main(2)))/1000); % kWh/m2
        if daily_MV~=MV
            warning('The sum up of the daily radiation data of the year %d and month %d\n do not correspond with the monthly value of the candidate month.',...
                year,m)
        end
        % If no warnings: All values are coherent
        
        % Check difference between monthly irradiance value and RMV -------
        % Equation (6) Standard IEC 62862-1-2
        limit = (ARV(i)/12)*0.02; % Limit of the difference between monthly value and RMV
        if abs(RMV(m,i)-MV) >= limit
            days_m = [days_m_val(:,1) days_m_val(:,cols_main(2))/1000]; % # of day and daily irradiance in kWh/m2
            if MV <= RMV(m) % Monthly value must increment
                [resultado,usados,cambiados,contador,control]...
                    = subs_days_up(m,days_m,RMV(m),limit,max_dist,max_times,max_subs); % Function
            elseif MV > RMV(m) % Monthly value must decrement
                [resultado,usados,cambiados,contador,control]...
                    = subs_days_dw(m,days_m,RMV(m),limit,max_dist,max_times,max_subs); % Function
            end
        end
        
        % Apply the last substitutions ---
        
        
        % Output Series ---------------------------------------------------
        SERIES_out(row_m_obs_ini:row_m_obs_end,:,i) = series_m;
        DAYS_out(row_m_d_ini:row_m_d_end,:,i) = days_m_val;
        MONTHS_out(m,:,i) = month_val;
        cosz_out(row_m_obs_ini:row_m_obs_end) = cosz_m;
    end
    
    %% Calculation or Interpolation of the other variables
    % Variables not inclued in the validation process are interpolated
    [SERIES_out_int(:,:,i),num_cases] = interpolating_holes(SERIES_out(:,:,i),cosz_out,num_obs); % Function
    fprintf('Final interpolation results of the %s series\n',name_series);
    fprintf('# of GHI data calculated from the other variables: %d\n',num_cases(1));
    fprintf('# of DNI data calculated from the other variables: %d\n',num_cases(2));
    fprintf('# of DHI data calculated from the other variables: %d\n',num_cases(3));
    fprintf('# of DNI data interpolated and GHI calculated: %d\n',num_cases(4));
    fprintf('# of DNI data interpolated and DHI calculated: %d\n',num_cases(5));
    fprintf('# of GHI data interpolated and DHI calculated: %d\n',num_cases(6));
    fprintf('# of GHI, DNI data interpolated and DHI calculated: %d\n',num_cases(7));
        
    %% Write down EXCEL series report TODO
    filename_out = strcat(path_series,'\',namef,'-OUTPUT-GENERATION.xlsx'); % Output Generation
    fprintf('Generating EXCEL report for %s series\n',name_series);
    
    % Switch off new excel sheet warning
    warning off MATLAB:xlswrite:AddSheet

    % Write the definitive daily series of the typical year
    headerD{1} = 'Year'; headerD{2} = 'Month';
    headerD{3} = 'day GHI'; headerD{4} = 'GHI (Wh/m2)'; headerD{5} = 'fdvGHI';
    headerD{6} = 'day DNI'; headerD{7} = 'DNI (Wh/m2)'; headerD{8} = 'fdvDNI';
    
    % Year and month for daily results
    year_y = zeros(365,1); year_m = zeros(365,1); k = 1; % No leap years
    for month = 1:12
        for d = 1:num_days_m(month)
            year_y(k) = series_in(month,i);
            year_m(k) = month;
            k = k+1;
        end
    end
        
    xlswrite(filename_out,[headerD; num2cell([year_y year_m DAYS_out(:,:,i)])],...
        strcat(name_series,'_D'),'A1');
        
    % Write the definitive monthly series of the typical year
    headerM{1} = 'Year';
    headerM{2} = 'month'; headerM{3} = 'GHI (kWh/m2)'; headerM{4} = 'fmvGHI';
    headerM{5} = 'month'; headerM{6} = 'DNI (kWh/m2)'; headerM{7} = 'fmvDNI';
    
    xlswrite(filename_out,[headerM; num2cell([series_in(:,i) MONTHS_out(:,:,i)])],strcat(name_series,'_M'),'A1');
    
    %% Write down txt files
    % SAM CSV format ------------------------------------------------------
    if sam_format
        filename_out = strcat(path_series,'\','SAM_',namef,'_',name_series,'.csv');
        sam_out = SERIES_out_int(:,[1:5,7,9,11],i)'; % Without the flags
        % Continuous day in the month along the year (override day substitutions for final csv file)
        m31 = zeros(1,31*24*num_obs); k = 1;
        for d = 1:31
            for o = 1:24*num_obs
                m31(1,k) = d;
                k = k+1;
            end
        end
        m30 = m31(1,1:30*24*num_obs); m28 = m31(1,1:28*24*num_obs);
        year_d = [m31 m28 m31 m30 m31 m30 m31 m31 m30 m31 m30 m31]; % No leap years
        sam_out(3,:) = year_d;

        headerSAM{1,1} = 'Source,Location ID,City,Region,Country,Latitude,Longitude,Time Zone,Elevation';
        headerSAM{2,1} = [owner_station,',',loc,',',city,',',reg,',',country,',',...
            num2str(dataval.geodata.lat,'%.6f'),',',...
            num2str(dataval.geodata.lon,'%.6f'),',',...
            num2str(tzone,'%2.1f'),',',...
            num2str(dataval.geodata.alt,'%d')];
        labels{1} = 'Year'; labels{2} = 'Month'; labels{3} = 'Day'; labels{4} = 'Hour';
        labels{5} = 'Minute'; labels{6} = 'GHI'; labels{7} = 'DNI'; labels{8} = 'DHI';
        labels{9} = 'Tdry'; labels{10} = 'Tdew'; labels{11} = 'Twet'; labels{12} = 'RH';
        labels{13} = 'Pres'; labels{14} = 'Wspd';

        fprintf('Generating SAM CSV format file for %s series\n',name_series);

        fileID = fopen(filename_out,'W');
        for j = 1:size(headerSAM,1)
            fprintf(fileID,'%s\n',headerSAM{j});
        end
        for j = 1:size(labels,2)
            fprintf(fileID,'%s,',labels{j});
        end
        fprintf(fileID,'\n');
        fprintf(fileID,...
            '%d,%d,%d,%d,%d,%.0f,%.0f,%.0f\n',...
            sam_out);
        fclose(fileID);
    end
    
    % IEC 62862-1-3 format ------------------------------------------------
    if iec_format
        filename_out = strcat(path_series,'\','ASR_',namef,'_',name_series,'.txt');
        time_str = cellstr(datestr(SERIES_out_int(:,1:6,i),'yyyy-mm-ddTHH:MM:SS')); % Original date
        
        headers{1,1} = ['#MET_IEC.v1.0 headerlines: ', num2str(hl,'%d')];
        headers{2,1} = ['#characterset ', slCharacterEncoding()];
        headers{3,1} = ['#delimiter ', del];
        headers{4,1} = ['#endofline ', eol];
        headers{5,1} = ['#title ', namef];
        headers{6,1} = ['#history.',nowstr,histmsg];
        headers{7,1} = ['#comment ', cmt];
        headers{8,1} = ['#datasource ', ds];
        headers{9,1} = ['#user_defined_fields ', udf];
        headers{10,1} = ['#IPR.institution.name ', owner_station];
        headers{11,1} = '#IPR.copyrightText ExampleCR';
        headers{12,1} = '#IPR.contact someone@example.com';
        headers{13,1} = ['#location.latitudeDegrN ', num2str(dataval.geodata.lat,'%.4f')];
        headers{14,1} = ['#location.longitudeDegrE ', num2str(dataval.geodata.lon,'%.4f')];
        headers{15,1} = ['#location.elevationMAMSL ', num2str(dataval.geodata.alt,'%d')];
        headers{16,1} = ['#time.timezone ', dataval.timedata.timezone];
        headers{17,1} = ['#time.resolutiontype ', t_res];
        headers{18,1} = ['#time.resolutionSec ', num2str(3600/num_obs,'%d')];
        headers{19,1} = ['#time.averaging ', t_ave];
        headers{20,1} = ['#time.completeness ', t_com];
        headers{21,1} = ['#time.calender.leap_years ', t_leap];
        headers{22,1} = ['#gap.notanumber ' num2str(dataval.nodata)];
        headers{23,1} = '#QC.type.4 BSRN';
        headers{24,1} = '#QC.type.4 https://doi.org/10.1016/j.renene.2015.01.031';
        headers{25,1} = '#begindata';
        labelIEC{1} = 'time'; labelIEC{2} = 'time_orig'; labelIEC{3} = 'dni'; labelIEC{4} = 'dniqcflag';
        
        fprintf('Generating IEC 62862-1-3 format file for %s series\n',name_series);
        
        fileID = fopen(filename_out,'W');
        for j = 1:size(headers,1)
            fprintf(fileID,'%s\n',headers{j});
        end
        for j = 1:size(labelIEC,2)
            fprintf(fileID,'%s\t',labelIEC{j});
        end
        fprintf(fileID,'\n');
        for j = 1:size(SERIES_out,1)
            fprintf(fileID,...
                '%s\t %s\t %4.0f\t %3d\n',...
                time_func_str{j}, time_str{j}, SERIES_out_int(j,9:10));
        end
        fprintf(fileID,'#enddata');
        fclose(fileID);
    end
    
    %% Plot figures
    % Plotting solar radiation outputs
    figure;
    plot(SERIES_out_int(:,7,i) ,'-b') % Definitive GHI series -------------
    axis([1 365*24*num_obs 0 1600]); grid on;
    title([name_series,' - GHI'],'Fontsize',16);
    xlabel('Observations','Fontsize',16);
    ylabel('W/m^2','Fontsize',16);
    filename = strcat(name_series,'-GHI');
    print('-djpeg','-opengl','-r350',strcat(path_fig,'\',filename))
    
    figure;
    plot(SERIES_out_int(:,9,i) ,'-r') % Definitive DNI series -------------
    axis([1 365*24*num_obs 0 1600]); grid on;
    title([name_series,' - DNI'],'Fontsize',16);
    xlabel('Observations','Fontsize',16);
    ylabel('W/m^2','Fontsize',16);
    filename = strcat(name_series,'-DNI');
    print('-djpeg','-opengl','-r350',strcat(path_fig,'\',filename))
    
    figure;
    plot(SERIES_out_int(:,11,i),'-c') % Definitive DHI series -------------
    axis([1 365*24*num_obs 0 1000]); grid on;
    title([name_series,' - DHI'],'Fontsize',16);
    xlabel('Observations','Fontsize',16);
    ylabel('W/m^2','Fontsize',16);
    filename = strcat(name_series,'-DHI');
    print('-djpeg','-opengl','-r350',strcat(path_fig,'\',filename))
    close all
    
    % Daily figures - Are you sure you want to do this? -------------------
    numD = 0;
    for month = 1:12
        for day = 1:num_days_m(month)
            numD = numD+1;
            first = (numD-1)*24*num_obs+1;
            last = numD*24*num_obs;
            
            day_piece = SERIES_out_int(first:last,:,i);
            
            year_str = num2str(day_piece(1,1));
            month_str = num2str(month);
            day_str = num2str(day);
            
            i0 = dataval.astro(first:last,9); % ???
            hour = day_piece(:,4);
            min = day_piece(:,5);
            hourdec = hour+min/60;
            GHI = day_piece(:,7);
            DNI = day_piece(:,9);
            DHI = day_piece(:,11);
            
            date_str = ['Month ' month_str ' - Day ' day_str ' - Year ' year_str];
            
            figure;
            plot(hourdec,i0,'-k'); hold on
            plot(hourdec,GHI,'b-o');
            plot(hourdec,DNI,'r-o');
            plot(hourdec,DHI,'c-o');
            axis([0 24 0 1600]);
            grid on
            title([name_series,' - ',date_str],'Fontsize',16);
            xlabel('Local Universal Time','Fontsize',16);
            ylabel('W/m^2','Fontsize',16);
            leg = legend('GHo','GHI','DNI','DHI');
            set(leg,'Fontsize',16);
            filename = strcat(name_series,'-',date_str);
            print('-djpeg','-opengl','-r350',strcat(path_fig,'\',filename))
            close all
        end
    end
    
end

save(strcat(path_tmy,'\','output_series'),'SERIES_out_int','DAYS_out',...
    'MONTHS_out'); % Save results

