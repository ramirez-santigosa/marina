%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% MODULE 1: TOFORMAT
% Version of July, 2015. L. Ramírez; At CSIRO.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT: 
%  ..\DATA\(ANNUAL DIRECTORIES PER YEAR)
%           monthly files form BSRN (1995-2014)
%           (i.e.:'ASP_1995-01_0100.txt')
%
% OUTPUTS: 
% ..\OUTPUTS\1_FORMAT\
% (1)   One matlab file per year: datos    'ASP00-BOM-01-1995' 
%       Each file contains the structured variable   'datos'
% (2)   One matlab file per year           'Summary1995'
%           aaaa mmm GHI DNI DHI
%           Values: -1 no file; 0 wrong file; column number in INPUT file
%-------------------------------------------
% datos.filedata.own: owner
% datos.filedata.loc: location 
% datos.filedata.name: name for the output information
% datos.geodata.lat => latitude [ºN]
% datos.geodata.lon => longitude[ºE]
% datos.geodata.alt => height [m]
% datos.timedata.timezone   => zona horaria
% datos.timedata.etiq       => 0 ini int; 0.5 centre int; 1 end int.
% datos.timedata.num_obs    => num obs / hora
% datos.nodata  => -999
% datos.mat => matriz:AAAA MM DD HH mm ss (INPUT)/ GHI DNI DHI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
clc
close all

run('Configuration_BSRN_ASP.m');

for anno=anno_ini:anno_end
    
    anno_str     = num2str(anno);
    fprintf('Treatment of %s year %s\n',name,anno_str); 
    filedata.ID     = anno_str; 

    [name_out,datos]=Year_BSRN_to_format(ruta_in,ruta_format,filedata,timedata,nodata,anno);
    save(strcat(ruta_format,'\',name_out),'datos');

end    
    
