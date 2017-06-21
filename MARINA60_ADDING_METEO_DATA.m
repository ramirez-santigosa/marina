%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% MODULE 6: ADDING METEO DATA
% Version of July, 2015. L. Ramírez; At CSIRO.
% Update F. Mendoza (June 2017) at CIEMAT.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT
%  (1) OUTPUT-GENERACION (3 sheets by case)
%        sheet CASE_Dini   initial daily values
%        sheet CASE_Dfin   final daily values
%        sheet CASE_M      final monthly values
%  (2) TMY-ASTRI-CASE.TXT
%        txt file: aaaa mm dd hh MM SS GHI eGHI DNI eDNI DHI eDNI
%
% OUTPUT
% ..\OUTPUT\4_ASR\NAME_SERIES
%  (2) TMY-ASTRI-CASE.TXT
%      txt file: aaaa mm dd hh MM SS GHI eGHI DNI eDNI DHI eDNI WEADER
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close, clearvars -except cfgFile, %clc
run(cfgFile); % Run configuration file

if ~exist(path_asr,'dir')
    mkdir(path_asr);
end

namef = [loc '00-' owner_station '-' num]; % General name for the series
load(strcat(path_asr,'\','out_series')); % Load final radiation series
load(strcat(path_val,'\',namef,'-',num2str(series_in(1,1)),'_VAL')); % Get any validation structure for geo data
num_series = size(SERIES_out_int,3); % Number of series to add meteo data and print
headers_m = {'Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';'Aug';'Sep';'Oct';'Nov';'Dic'}; % Headers months
% Additional data elements from the weather file required by SAM to
% execute a CSP plant simulation. See SAM Help.
addMeteo = {'t_air [degC]','rh [%]','bp [hPa]','ws [m/s]'};
addVars = size(addMeteo,2);

if iec_format % Create a functional date vector in ISO 8601 format if IEC 62862-1-3 format is required
    time_func = (datetime([2015 1 1 0 0 0]):minutes(60/num_obs):...
        datetime([2015 12 31 23 60-60/num_obs 0]))'; % Functional date (IEC 62862-1-3)
    time_func_str = cellstr(datestr(time_func,'yyyy-mm-ddTHH:MM:SS')); % Functional date
end

%% Read other meteorological database
freadmeteo = strcat(path_meteo,'\',meteofile);
[headersMeteo, meteonormData] = read_MeteoData(freadmeteo,num_obs_meteo);

%% Match data frequency
if num_obs==num_obs_meteo % Same sampling frequency
    METEO_out = meteonormData(:,8:end); % Only the additional meteorological variables are considered
elseif num_obs>num_obs_meteo % Interpolate to keep the original higher sampling
    xq = transpose(1:8760*num_obs);
    meteoFreq = num_obs/num_obs_meteo;
    x = transpose(1:meteoFreq:8760*num_obs); x = [x; xq(end)]; % Add a row to interpolate the last hour
    METEO_out = interp1(x,[meteonormData(:,8:end); meteonormData(end,8:end)],xq,'linear'); % Only the additional meteorological variables are interpolated
    num_obs_meteo = num_obs;
else % Reduce the intrahourly frequency to match the radiation sampling frequency
    METEO_out = reduce_intrahour_freq(meteonormData(8:end),num_obs_meteo,num_obs,0); % Only the additional meteorological variables are considered
    num_obs_meteo = num_obs;
end

%% Get the column number of the wanted variables
varsMeteoSAM = {'Tdry','RH','Pres','Wspd'}; % Wanted additional variables
cols = false(1,length(headersMeteo)-7); % Seven initial columns are date and radiation
for v = 1:addVars
    colv = strcmp(varsMeteoSAM(v),headersMeteo(8:end));
    cols = cols|colv;
end
cols = find(cols);

% Loops through Series and Months
for i = 1:num_series
    path_series = strcat(path_asr,'\',name_series{i});
    if ~exist(path_series,'dir')
        mkdir(path_series);
    end
    
    fprintf('\nAdding meteorological data to the %s series for simulation.\n',name_series{i});
    
    %% Verify which additional meteo data is included
    if cellfun(@isempty,otherMeteo)
        fprintf('There are not the additional meteorological data required for simulation of the %s series.\n',...
            name_series{i});
    else
        available = false(12,addVars);
        for month = 1:12
            for v = 1:addVars
                avl = strcmp(otherMeteo(month,v,i),addMeteo);
                available(month,:) = available(month,:)|avl;
            end
            
            missMeteo = addMeteo(~available(month,:));
            if ~isempty(missMeteo)
                fprintf('For %s, %d is missing the following meteorological data: ',...
                    headers_m{month},series_in(month,i))
                for k = 1:length(missMeteo)
                    fprintf('%s ', missMeteo{k});
                end
                fprintf('\n');
            end
        end
    end

    %% Add the meteo data
    SERIES_out_int(:,13:end,i) = METEO_out(:,cols); % Columns of the wanted variables

    %% Write down SAM CSV format ------------------------------------------
    if sam_format
        filename_out = strcat(path_series,'\','SAM_',namef,'_',name_series{i},'.csv');
        sam_out = SERIES_out_int(:,[1:5,7,9,11,13:end],i); % [Year Month Day Hour Minute GHI DNI DHI t_air rh bp ws]
        % Continuous day in the month along the year (override day substitutions for final csv file)
        m31 = zeros(1,31*24*num_obs); l = 1;
        for d = 1:31
            for o = 1:24*num_obs
                m31(1,l) = d;
                l = l+1;
            end
        end
        m30 = m31(1,1:30*24*num_obs); m28 = m31(1,1:28*24*num_obs);
        year_d = [m31 m28 m31 m30 m31 m30 m31 m31 m30 m31 m30 m31]; % No leap years
        sam_out(:,3) = year_d; % Update days without substitutions [Year Month "Day"]
        
        options_sam.lat = dataval.geodata.lat; % Add geodata from data validation structure
        options_sam.lon = dataval.geodata.lon;
        options_sam.alt = dataval.geodata.alt;
        fprintf('Generating SAM CSV format file for %s series\n',name_series{i});
        sam_write(filename_out,sam_out,options_sam); % Function
    end
    
    %% Write down IEC 62862-1-3 format ------------------------------------
    if iec_format
        filename_out = strcat(path_series,'\','ASR_',namef,'_',name_series{i},'.txt');
        iec_out = SERIES_out_int(:,[1:6,7,9,11,13:end],i); % % [Year Month Day Hour Minute Second GHI DNI DHI t_air rh bp ws]
        options_iec.lat = dataval.geodata.lat; % Add geodata from data validation structure
        options_iec.lon = dataval.geodata.lon;
        options_iec.alt = dataval.geodata.alt;
        fprintf('Generating IEC 62862-1-3 format file for %s series\n',name_series{i});
        iec_write(filename_out,iec_out,time_func_str,num_obs,options_iec); % Function
    end
    
end

save(strcat(path_asr,'\','out_series_meteo'),'SERIES_out_int'); % Save results
% save(strcat(ruta_tmy,'\','output_series_meteo'),'salidas',...
%     'num_series','raw','datosval');
