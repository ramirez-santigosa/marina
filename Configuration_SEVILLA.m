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
% 
% CASE: SEVILLA ETSI
% INPUT INFORMATION
%---------------------------------------------------------
% ENTRADAS:
% filedata: datos para la creación del nombre de fichero de salida
%   filedata.loc: localidad 
%   filedata.own: propietario
%   filedata.num: numero de estación (de igual localidad y propietario)
%   filedata.ID : identificador del fichero
%   filedata.name: nombre identificador de los datos
% geodata: datos geográficos de la ubicación
%   geodata.lat: latitud [ºN] 
%   geodata.lon: longitud [ºE]
%   geodata.alt: altitud [m]
% timedata: datos asociados a la referencia horaria de los datos
%   timedata.timezone: zona horaria ('UTC+','VALOR') 
%   timedata.num_obs: numero de observaciones pro hora
%   timedata.etiqueta: instante de la etiqueta de los datos
%                      0 al principio, 0.5 si al medio, 1 si al final
% nodata:
%   nodata: nodata value
% fechas: vector de fechas de los datos
%   ha de corresponder con los vectores de los datos de entrada
%   la frecuencia temporal es indistinta
%   [aaaa mm dd hh mm] en caso de datos minutales
% GHI,DNI,DHI,OTRAS
%   vectores de igual longitud, y con información de los datos
%   correspondientes.
%   OTRAS: matriz con otras variables adicionales

% Specific of threatment
anno_ini = 2012;
anno_end = 2012;  % use the seam as ini in case 1 year.

zonaH   = 0;
name    = 'SEVILLA'; % ID BSRN + 00
loc     = 'SEV';
owner_station = 'ETS';  
lat = 37.3824;
lon = -5.97613;
alt = 100;
ref_temp     = 'UTC+01'; % TSV / UTCSXX (S signo; XX corrección)
time_stamp   = 0;        % Values: 0/0.5/1 related to beguining/mid/end
num_obs = 1;
no_data      = NaN;
level = 1; % level for validation

%fichero de resutlado de la validación
file_val = 'SEV00-ETS-01.xlsx';

% numero de preseleccionados para la seleccion de candidatos
% 1 si ya tenemos los valores objetivos
num_pre=1; 

name_input_generation= 'INPUT2-GENERATION';
name_out_generation  = 'OUTPUT301015-GENERACION';

% Max. num of changes allowed each month.
max_cambios=30;
% Max. distance in the days used for the sustitution
dist_dias=10;
% Max. tiems that a day can be repeated in the month
max_uso=15;

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
geodata.lat       = lat;
geodata.lon       = lon;
geodata.alt       = alt;
%-----------------------------------------------------------------
ruta_in  = '..\P90'; %INPUT DATA IN ANNUAL FOLDERS INSIDE: \aaaa\
%ruta_meteo = '..\METEOData'; %Meteo data in annual excel files
ruta_format  = '..\OUTPUT_Sev\1_FORMAT';
ruta_qc      = '..\OUTPUT_Sev\2_QC';
ruta_val     = '..\OUTPUT_Sev\3_VALIDATION';
ruta_cases   = '..\OUTPUT_Sev\4_CASES';
ruta_tmy     = '..\OUTPUT_Sev\5_TMY';
%ruta_trans     = '..\OUTPUT\6_TRANS';

file_IN=strcat(ruta_val,'\',file_val);

% XLS file with the INPUT information for the series generation
filename_input=strcat(ruta_cases,'\',name_input_generation);

% XLS fiel with the information of the output series
filename_out  =strcat(ruta_tmy,'\',name_out_generation); 

num_dias_mes=[31 28 31 30 31 30 31 31 30 31 30 31];

