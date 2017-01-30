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

run('Configuration_SEVILLA.m');

anno=2012;
anno_str  = num2str(anno);
filedata.ID = anno_str; 

[datos,texto]=xlsread('..\P90\Datos_Sevilla_P90.xlsx','datos');

fechas_anno=datos(:,1:4);
GHI=[];
DNI=datos(:,5);
DHI=[];
OTRAS=[];
[name_out,datos]=...
   make_standard_data(filedata,timedata,nodata,geodata,...
   fechas_anno,GHI,DNI,DHI,[]);

header{1,1}='ano';
header{1,2}='mes';
header{1,3}='dia';
header{1,4}='hora';
header{1,5}='DNI';

datos.header = header;
[s,mess,messid] = mkdir(ruta_format);
save(strcat(ruta_format,'\',name_out),'datos');
    
