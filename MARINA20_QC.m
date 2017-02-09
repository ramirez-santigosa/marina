%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% MODULE 2: QC (Quality control)
% Version of July, 2015. L. Ramírez; At CSIRO.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT: 
% ..\OUTPUTS\1_FORMAT
%       One matlab file per year: datos    'ASP00-BOM-01-1995' 
%       Each file contains the structured variable   'data'
% 
% OUTPUTS: 
% ..\OUTPUT\2_QC
%       One matlab file per year: dataqc   'ASP00-BOM-01-1995_QC' 
%       Each file contains the structured variable   'dataqc'
%       Same as "datos" but adding two more variables,
%           (records are sorted and a the year is full)
%  (1)  datos.matc  = [fecha_vec(:,1:6)(TSV)/ GHIord eGHI DNIord eDNI DHIord eDHI];
%  (2)  datos.astro = [dj e0 ang_dia et tsv_horas w dec cosz i0 m];
%
%       figuras filtros por variables
%       figura ghi medida vs. calculada
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars -except year_ini year_end ref_temp time_stamp num_obs no_data...
    tzone name loc owner_station path_in path_meteo path_format path_qc...
    path_val path_cases path_tmy path_trans filedata
close %clc
% run('Configuration_BSRN_ASP.m');

for y = year_ini:year_end
        
    year_str = num2str(y);
    fprintf('Quality control of %s year %s\n',name,year_str);

    path_fig_year_ini = strcat(path_qc,'\','figures');
    if ~exist(path_fig_year_ini,'dir')
        mkdir(path_fig_year_ini);
    end
    
    var = [1 1 1]; % Variables for QC process [GHI DNI DHI] 1(yes)/0(no)
    offset_empirical = 0; % Just in case the results seems have timestamp mistakes
    max_rad = 1600; % max. solar radiation value for the figures
    
    % Columns of the .mat matrix
    mat_cols.date = 1:6; % dates[1..6];
    mat_cols.GHI = 7;   
    mat_cols.DNI = 8;   
    mat_cols.DHI = 9;   

    filedata.ID = year_str; 
    
    name_out = [filedata.loc '00-' filedata.own '-' filedata.num '-' filedata.ID];
    load(strcat(path_format,'\',name_out)); % Load of the standard data structure
    
    [dataqc] = QC_JULY_2015...
       (path_fig_year_ini,data,var,max_rad,mat_cols,tzone,offset_empirical);  
    close all
    
    save(strcat(path_qc,'\',name_out,'_QC'),'dataqc');
    
end    
