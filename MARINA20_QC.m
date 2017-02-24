%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% MODULE 2: QC (Quality control)
% Version of July, 2015. L. Ramírez; At CSIRO.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT: !!!
% ..\OUTPUTS\1_FORMAT
%       One matlab file per year: datos    'ASP00-BOM-01-1995' 
%       Each file contains the structured variable   'data'
% 
% OUTPUTS: 
% ..\OUTPUT\2_QC
%       One matlab file per year: dataqc   'ASP00-BOM-01-1995_QC' 
%       Each file contains the structured variable   'dataqc'
%       Same as "data" but adding two more variables,
%       (records are sorted and a the year is full)
%  (1)  data.mqc  = [fecha_vec(:,1:6)(TSV)/ GHIord eGHI DNIord eDNI DHIord eDHI];
%  (2)  datos.astro = [dj e0 ang_dia et tsv_horas w dec cosz i0 m];
%
%       figuras filtros por variables
%       figura ghi medida vs. calculada
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close, clearvars, %clc
run('Configuration_BSRN_ASP.m');
% clearvars -except year_ini year_end tzone owner_station loc name num...
% ref_temp time_stamp num_obs no_data path_in path_meteo path_format path_qc...
% path_val path_cases path_tmy path_trans filedata

for y = year_ini:year_end
            
    year_str = num2str(y);
    fprintf('Quality control of %s year %s\n',name,year_str);

    path_fig_year_ini = strcat(path_qc,'\','figures');
    if ~exist(path_fig_year_ini,'dir')
        mkdir(path_fig_year_ini);
    end
    
    var = logical([1 1 1]); % Variables for QC process [GHI DNI DHI] 1(true)/0(false)
    offset_empirical = 0; % Just in case the results seem to have timestamp mistakes
    max_rad = 1600; % Max. solar radiation value for the figures
    
    % Columns of the variable in the data matrix
    mat_cols.date = 1:6;
    mat_cols.GHI = 7;
    mat_cols.DNI = 8;
    mat_cols.DHI = 9;
    
    ID = year_str;
    
    name_out = [loc '00-' owner_station '-' num '-' ID];
    load(strcat(path_format,'\',name_out)); % Load of the standard data structure
    
    [dataqc] = QC(path_fig_year_ini,data,var,max_rad,mat_cols,tzone,'Alice Spring ',offset_empirical);
    close all
    
    save(strcat(path_qc,'\',name_out,'_QC'),'dataqc');
    
end
