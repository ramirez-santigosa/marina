%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% MODULE 2: QC (Quality control)
% Version of July, 2015. L. Ramírez; At CSIRO.
% Update F. Mendoza (February 2017) at CIEMAT.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT:
% ..\OUTPUT\1_FORMAT
%       One Matlab file per year i.e. 'loc00-owner_station-num-YYYY'
%       Each file contains the structured variable 'data'
%
% OUTPUT:
% ..\OUTPUT\2_QC
%       One Matlab file per year i.e. 'loc00-owner_station-num-YYYY_QC'
%       Each file contains the structured variable 'dataqc'
%       Same as "data" but adding two fields
%       (records are sorted and the year is complete)
%  (1)  dataqc.mqc  = [date_vec(:,1:6)(TST) GHIord fGHI DNIord fDNI DHIord fDHI]
%  (2)  datosqc.astro = [dj e0 ang_day et tst_hours w dec cosz i0 m]
%
%       Figures Tests per variables
%       Figures GHI measured vs. calculated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close, clearvars, %clc
run('Configuration_BSRN_ASP.m');

for y = year_ini:year_end
    
    year_str = num2str(y);
    fprintf('Quality control of %s year %s\n',name,year_str);
    
    path_fig_year_ini = strcat(path_qc,'\','figures');
    if ~exist(path_fig_year_ini,'dir')
        mkdir(path_fig_year_ini);
    end
    
    % Columns of the variable in the data matrix
    mat_cols.date = 1:6;
    mat_cols.GHI = 7;
    mat_cols.DNI = 8;
    mat_cols.DHI = 9;
    
    ID = year_str;
    
    name_out = [loc '00-' owner_station '-' num '-' ID];
    load(strcat(path_format,'\',name_out)); % Load of the standard data structure
    
    dataqc = QC(path_fig_year_ini,data,vars,max_rad,mat_cols,tzone,name,Isc,offset_empirical);
    close all
    
    save(strcat(path_qc,'\',name_out,'_QC'),'dataqc');
    
end
