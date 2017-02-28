%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% MODULE 3: VALIDATION (Days and months valids)
% Version of July, 2015. L. Ramírez; At CSIRO.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT: 
% ..\OUTPUT\2_QC
%       One matlab file per year: datosc   'ASP00-BOM-01-1995_QC' 
%       Each file contains the structured variable   'datosc'
%       Same as "datos" but adding two more variables,
%           (records are sorted and a the year is full)
%  (1)  datos.matc  = [fecha_vec(:,1:6)(TSV)/ GHIord eGHI DNIord eDNI DHIord eDHI];
%  (2)  datos.astro = [dj e0 ang_dia et tsv_horas w dec cosz i0 m];
%
% OUTPUTS: 
% ..\OUTPUT\3_VALIDATION
% (1)   One matlab file per year: datosval 'ASP00-BOM-01-1995_VAL' 
%       Each file contains the structured variable   'datosc'
%       Same as "datosc" but adding four more variables,
%      (1) diarios      365 X 6 columns by year (DAY   GHI VAL DAY   DNI VAL)
%      (2) mensuales    12  X 6 columns by year (month GHI VAL month DNI VAL)
%      (3) cambios      description of the changes of the year
%      (4) cambios_mes  number of not valid or changed days by month
% (2)   output EXCEL file:
%              sheet Val-dia
%              sheet Val-mes
%              sheet Tabla-GHI
%              sheet Tabla-DNI
%              sheet Tabla-FALTAN
%              sheet cambiados
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
clc
close all
run('Configuration_BURNS.m');

[s,mess,messid] = mkdir(ruta_val);

% Initializin results
res_diaria =[]; res_mes   = []; cambiados    = []; 
% cabeceras de la validación diaria/mensual/tablas mensuales
headerd   = []; headerm   = []; header_annos = [];
%inicialización Tablas salida validacíon
Tabla_FALTAN = []; Tabla_GHI = []; Tabla_DNI = [];



for anno = anno_ini:anno_end
    anno_str     = num2str(anno);

    disp(sprintf('Validation of %s year %s',name,anno_str)); 
    cambios_anno = [];
    
    
    name     = [filedata.loc '00-' filedata.own '-' filedata.num];
    name_out = [name '-' anno_str];
    name_out_QC  = [name_out '_QC'];
    name_out_VAL = [name_out '_VAL'];

    load(strcat(ruta_qc,'\',name_out_QC));
    
    datosval = validation(datosc,level);

    save(strcat(ruta_val,'\',name_out_VAL),'datosval');

    % save de validation results for excel recording
    res_diaria = [res_diaria datosval.diarios];
    res_mes    = [res_mes    datosval.mensuales];
    
    Tabla_FALTAN = [Tabla_FALTAN datosval.cambios_mes(:,1)];
    Tabla_GHI    = [Tabla_GHI datosval.mensuales(:,2)];
    Tabla_DNI    = [Tabla_DNI datosval.mensuales(:,5)];

    cambios = datosval.cambios;
    
    % creamos cambios_anno, que tiene la columna del valor del año
    if ~isnan(cambios)
        cambios_anno(:,2:4) = cambios;
        cambios_anno(:,1) = anno;
        cambiados = [cambiados;cambios_anno];
    end
end    
    
% WRITTING IN THE SHEETS OUTPUTS FOF THE VALIDATION
%------------------------------------------------------------------------
if isempty(cambiados)
    cambiados='####';
end

% Formatting headers
for i=1:num_annos
    anno=anno_ini+i-1;
    anno_str=num2str(anno);
    
    % Header of daily validation
    cab_d(1,:)=[anno_str '_dia'];
    cab_d(2,:)=[anno_str '_GHI'];
    cab_d(3,:)=[anno_str '_eGI'];
    cab_d(4,:)=[anno_str '_dia'];
    cab_d(5,:)=[anno_str '_DNI'];
    cab_d(6,:)=[anno_str '_eDI'];
    cab_d_anno={cab_d(1,:),cab_d(2,:),cab_d(3,:),cab_d(4,:),cab_d(5,:),cab_d(6,:)};
    headerd=[headerd,cab_d_anno];

    % Header of monthly validation
    cab_m(1,:)=[anno_str '_mes'];
    cab_m(2,:)=[anno_str '_GHI'];
    cab_m(3,:)=[anno_str '_eGI'];
    cab_m(4,:)=[anno_str '_mes'];
    cab_m(5,:)=[anno_str '_DNI'];
    cab_m(6,:)=[anno_str '_eDI'];
    cab_m_anno={cab_m(1,:),cab_m(2,:),cab_m(3,:),cab_m(4,:),cab_m(5,:),cab_m(6,:)};
    headerm=[headerm,cab_m_anno];
    
    header_annos=[header_annos,anno]; 
    
end

% Name of the output EXCEL file 
file_xls=strcat(ruta_val,'\',name,'.xlsx');

% Switch of warning of new excel sheet.
warning off MATLAB:xlswrite:AddSheet

% Process information
disp(sprintf('Writting in the file %s ',name)); 

% DAILY VALIDATION RESULTS
% -----------------------------------------------------------------------
% write the header
xlswrite(file_xls, headerd,          'Val-dia','A1');
% Write the results
xlswrite(file_xls, round(res_diaria),'Val-dia','A2');
% MONTHLY VALIDATION RESULTS
%---------------------------------------------------------------------
% write the header
xlswrite(file_xls, headerm,          'Val-mes', 'A1');
% Write the results
xlswrite(file_xls, round(res_mes),   'Val-mes', 'A2');

% Write the final tables  
xlswrite(file_xls, header_annos,     'Tabla-GHI', 'A1');
xlswrite(file_xls, round(Tabla_GHI), 'Tabla-GHI', 'A2');

xlswrite(file_xls, header_annos,     'Tabla-DNI', 'A1');
xlswrite(file_xls, round(Tabla_DNI), 'Tabla-DNI', 'A2');

xlswrite(file_xls, header_annos,        'Tabla-faltan', 'A1');
xlswrite(file_xls, round(Tabla_FALTAN), 'Tabla-faltan', 'A2');

xlswrite(file_xls, {'año','mes','dia_ini','dia_fin'},'Cambiados','A1');
xlswrite(file_xls, cambiados,                        'Cambiados','A2');
