function [astro,tst_num,UTC_num] = calcula_astro_may_2015...
    (date_num,stamp,num_obs,time,lat,lon,offset_empirical)
%CALCULA_ASTRO_MAY_2015 This function ...
%   INPUT:
%   date_num: 
%   stamp: 
%   num_obs: 
%   time: 
%   lat: 
%   lon: 
%   offset_empirical: 
%
%   OUTPUT:
%   astro: 
%   tst_num: 
%   UTC_num: 
%
% Cálculos astronómicos
% 
% Transforma la hora de entrada a TSV y hace los cálculos en el instante
% centrado. 
%
% salida: vector de 10 columnas:
%       1  2     3    4     5      6  7   8   9 10   
%       dj e0 ang_dia et tsv_horas w dec cosz i0 m
% entrada:
%       fecha_num: vectro de fechas de cálculo
%       cols_sal: columnas de salida de la fecha (4 horarios)
%       etiq: 0 inicio del intervalo; 0.5 centro; 1 fin 
%       num_obs:_ número de observaciones por hora
%       time: 'TSV' ó 'UTC+0' ó 'UTC+1'....

%% Intro
lat_rad = lat*pi/180; % Latitude in radians
Isc=1367; % Solar constant

% Centra el momento a mitad del intervalo para cálculos astronómicos
switch stamp
    case 0 % beginning of the interval
        date_num_center = date_num+(0.5/(24*num_obs)); 
    case 0.5 % middle of the interval
        date_num_center = date_num;
    case 1 % end of the interval
        date_num_center = date_num-(0.5/(24*num_obs));
    otherwise
        date_num_center = date_num;
end

date_vec_center = datevec(date_num_center);

%% CÁCULOS ASTRONÓMICOS
% DIARIOS (asumimos TSV) !!!
dj = floor(date_num)-datenum(date_vec_center(:,1),1,1)+1;
e0 = 1+0.033*cos(2*pi*dj/365);
ang_day = double(2*pi*(dj-1)/365);
et = 229.18*(0.000075+0.001868*cos(ang_day)-0.032077*sin(ang_day)...
    -0.014615*cos(2*ang_day)-0.04089*sin(2*ang_day));

% a considerar si no es TSV
sumGMT2TST = ((et./60)+(lon./15))./24; % Days
% time_corr = sumarGMT2TSV;
time_corr = date_num;
time_corr(:,:)= NaN;

% analiza la situación real 
if strcmp(time(1:3),'TST')
    time_corr(:) = 0;
    off = 0;
else
    if strcmp(time(1:3),'UTC')
        off = str2double(time(4:end));
    else
        off = 0;
        warning('Esto debería ser un warning')
    end
    time_corr = sumGMT2TST;
end

tst_num = date_num_center+time_corr-(off/24)+offset_empirical/24;

tst_hours = (tst_num-floor(tst_num))*24; % Parte de las horas (decimales)
w         = (12-tst_hours)*15*pi/180;
dec       = 0.006918-0.399912*cos(ang_day)+0.070257*sin(ang_day)...
            -0.006758*cos(2*ang_day)+0.000907*sin(2*ang_day)...
            -0.002697*cos(3*ang_day)+0.00148*sin(3*ang_day);

cosz = sin(dec).*sin(lat_rad)+cos(dec).*cos(lat_rad).*cos(w);

i0          = Isc.*e0.*cosz;
pos_neg     = find(i0<=0);
pos_pos     = find(i0>0);
i0(pos_neg) = 0; % para poner a cero los negativos si los hubiera

m = zeros(size(dj));
m(pos_neg) = max(m(pos_pos));
m(pos_pos) = 1./(cosz(pos_pos)+0.50572.*(96.07995-(acos(cosz(pos_pos)).*180/pi)).^-1.6364);

%% OUTPUT
%TRATAMIENTO DE LAS FECHAS
%pasa a UTC
%centra el momento a ppio del intervalo (en días)
UTC_num = tst_num-sumGMT2TST-(offset_empirical/24)-(0.5/(num_obs*24)); 
astro   = double([dj e0 ang_day et tst_hours w dec cosz i0 m]);
