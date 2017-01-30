%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% CONFIGURATION OF VARIABLES
% Version of July, 2015. L. Ramírez; At CSIRO.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION OF VARIABLES FOR THE THREATMENT OF
% BSRN SOLAR RADIATION DATA
% CASE: ALICE SPRING
% INPUT INFORMATION
%---------------------------------------------------------
% Specific years of threatment
anno_ini = 1995;
anno_end = 2014;  % use the seam as ini in case 1 year.
% Specific for Alice Spring
zonaH   = 9.5;
name    = 'ALICE_SPRING_BSRN'; % ID BSRN + 00
loc     = 'ASP';
owner_station = 'BOM'; % Boureau of Meterology 
% General for BSRN STATION   
ref_temp     = 'UTC+00'; % TSV / UTCSXX (S signo; XX corrección)
time_stamp   = 0;        % Values: 0/0.5/1 related to beguining/mid/end
num_obs = 60;
no_data      = NaN;
%---------------------------------------------------------
% datos.filedata.own: owner
% datos.filedata.loc: location 
% datos.filedata.name: name for the output information
% datos.geodata.lat => latitude [ºN]
% datos.geodata.lon => longitude[ºE]
% datos.geodata.alt => height [m]
% datos.timedata.timezone   => zona horaria
% datos.timedata.etiq       => 0 ini int; 0.5 centre int; 1 end int.
% datos.timedata.num_obs    => num obs / hora
% datos.nodata              => nodata value
% datos.mat => matriz:AAAA MM DD HH mm ss (AS INPUT) GHI DNI DHI

% DO NOT CHANGE THE NEXT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
num_annos = anno_end-anno_ini+1;
filedata.own  = owner_station; % Bureau of MEteorology
filedata.loc  = loc; % 
filedata.name = strcat(name);
filedata.num    = '01'; % num of the station (could be more than one station)
timedata.timezone = ref_temp;
timedata.etiq     = time_stamp;        
timedata.num_obs  = num_obs;  
nodata            = no_data;
%-----------------------------------------------------------------
ruta_in  = '..\BSRNData'; %INPUT DATA IN ANNUAL FOLDERS INSIDE: \aaaa\
ruta_meteo = '..\METEOData'; %Meteo data in annual excel files
ruta_format  = '..\OUTPUT\1_FORMAT';
ruta_qc      = '..\OUTPUT\2_QC';
ruta_val     = '..\OUTPUT\3_VALIDATION';
ruta_cases   = '..\OUTPUT\4_CASES';
ruta_tmy     = '..\OUTPUT\5_TMY';
ruta_trans     = '..\OUTPUT\6_TRANS';
num_dias_mes=[31 28 31 30 31 30 31 31 30 31 30 31];

