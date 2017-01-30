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
%       Each file contains the structured variable   'datos'
% 
% OUTPUTS: 
% ..\OUTPUT\2_QC
%       One matlab file per year: datosc   'ASP00-BOM-01-1995_QC' 
%       Each file contains the structured variable   'datosc'
%       Same as "datos" but adding two more variables,
%           (records are sorted and a the year is full)
%  (1)  datos.matc  = [fecha_vec(:,1:6)(TSV)/ GHIord eGHI DNIord eDNI DHIord eDHI];
%  (2)  datos.astro = [dj e0 ang_dia et tsv_horas w dec cosz i0 m];
%
%       figuras filtros por variables
%       figura ghi medida vs. calculada
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
clc
close all
run('Configuration_BURNS.m');

for anno=anno_ini:anno_end
    
    anno_str     = num2str(anno);
    
    disp(sprintf('Treatment of %s year %s',name,anno_str)); 

    ruta_fig_anno_ini=strcat(ruta_qc,'\','figures');
    [s,mess,messid] = mkdir(ruta_fig_anno_ini);
    % columns of the .mat matrix
    mat_cols.date = 1:4; % dates[1..6];
    mat_cols.GHI = [];   
    mat_cols.DNI = 5;   
    mat_cols.DHI = [];   

    filedata.ID     = anno_str; 
    
    name_out = [filedata.loc '00-' filedata.own '-' filedata.num '-' filedata.ID];
    load(strcat(ruta_format,'\',name_out));
    
    [datosc]=QC_2016_P90...
       (ruta_fig_anno_ini,datos,var,max_rad,mat_cols,zonaH,ofset_empirico);  
%     close all
    
    save(strcat(ruta_qc,'\',name_out,'_QC'),'datosc');
    
end    
