function [datoscc]=QC_JUJY_2015...
    (ruta_fig,datos,var,max_rad,cols,zonaH,ofset_empirico)
%
% Datos de entrada: en formato estándar datos.*
%
% crea un vector ordenado, continuo, anual y completo con los datos de entrada
% calcula matricialmente las variables astronómicas y el QC
% crea figuras con el resultado del QC de las variables
%
% - L. Ramírez      (abril 2013)
% - S. Moreno       (junio 2014)
% - L. Zarzalejo, L ramírez (May 2015)
%
% Tiene en cuenta la zona horaria y convierte a TSV para los cálculos
% astronómicos, y la salida la dá ya en UTC.
% --------------------------------------------------------------------
% ENTRADA:
% ruta: path de donde quiero grabar las figuras
%
% datos.mat => matriz:AAAA MM DD HH MM SS  GHI DNI DHI  
% datos.geodata.lat => latitud [ºN]
% datos.geodata.lon => longitud[ºE]
% datos.geodata.alt => altitud [m]
% datos.timedata.timezone=> zona horaria
% datos.timedata.num_obs => num de observaciones por hora
% datos.timedata.etiq    => 0 ppio int; 0.5 centro int; 1 fin del int.
% datos.nodata  => -999
% datos.filedata.loc: localidad 
% datos.filedata.own: propietario
% datos.filedata.num: numero de estación (de igual localidad y propietario)
% datos.filedata.ID : identificador del fichero, por ejemplo año de datos
%
% var= vector lógico, identifica las variables de las que quiero hacer el cnotrol de calidad y las
%       figuras del control de calidad:
%       ejemplo var=[ 1 1 1]  de todas las variables
%       ejemplo var=[ 1 0 1]  de global y difusa
%
% --------------------------------------------------------------------
% FUNCTIONS
%   [astro,tsv_num,UTC_num]=calcula_astro(fecha_num,cols_sal,etiq,num_obs,time,lat,lon);
%
% --------------------------------------------------------------------
% SALIDA: 
% datos.* añadiendo las matrices .matc y .astro:
% datos.matc  = [AAAA MM DD HH MM SS GHIord eGHI DNIord eDNI DHIord eDHI];
% datos.astro = [dj e0 ang_dia et tsv_horas w dec cosz i0 m];
%
% siendo eGHI la etiqueta del control de calidad de la variable GHI en
% funcion de los procedimientos BSRN:
%   0 no supera el nivel 1,    valor no físicamente posible
%   1 no supera el nivel 2,    valor extremadaemente raro
%   2 no supera el nivel 3,    las tres componentes no son coherentes o no
%                              se puede comprobar
%   3 valor coherente con las tres variables registradas
%
 Micolormap=[1    0.2  0.2  ;...
             1    0.5  0  ;...
             1    1    0  ;...
             0.6  1   0.6;...
             0.3  0.9 0.3];
         
max_fig = max_rad; 

Isc = 1367; % constante solar

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ASIGNACIÓN DE LA INFORMACIÓN DE LOS DATOS DE ENTRADA
lat    = datos.geodata.lat;
lon    = datos.geodata.lon;
time   = datos.timedata.timezone;
num_obs = datos.timedata.num_obs;
nodata = datos.nodata;
etiq   = datos.timedata.etiq;
entrada = datos.mat;
anno    = datos.mat(12*num_obs,1);   % avoiding the first rows
file_name = ['Alice Spring ' num2str(anno) ]; %datos.filedata.name;
col.GHI = cols.GHI ;
col.DNI = cols.DNI ;
col.DHI = cols.DHI ;
col.DATE = cols.date ;

lat_rad=lat*pi/180;
%-------------------------------------
% assessing the jump needed in the time data
off=str2double(time(4:end)); % offset of the input data
jumpH = zonaH - off ;        % 
if zonaH >= 0
    time = strcat('UTC+',num2str(zonaH));
else
    time = strcat('UTC+',num2str(zonaH));
end

pos_nodata = (entrada==nodata);
entrada(pos_nodata) = NaN;

GHI = entrada(:,cols.GHI); 
DNI = entrada(:,cols.DNI); 
DHI = entrada(:,cols.DHI);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% input dates, to local time (now data stars in the previos year)
date_vec = entrada(:,col.DATE);
if numel(date_vec(1,:))==4
    date_vec(:,5)=0;date_vec(:,6)=0;
end
date_num = datenum(date_vec); %fechas de entrada en días
date_num = date_num + jumpH/24; %  MOVE TO LOCAL TIME
date_num_min = round(date_num*24*num_obs); %en minutos, importante por el redondeo!!

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CREACIÓN DE LA SERIE ORDENADA, CONTINUA Y COMPLETA CON LOS DATOS

date_ini = floor((datenum([anno 1   1 0 0 0]))); %dia de inicio
date_fin = floor((datenum([anno 12 31 0 0 0]))); %dia de fin

date_ini_min = floor(date_ini*24*num_obs); %dia de inicio en minutos

%número de días con datos
num_dias = date_fin-date_ini+1;

%crea un vector con el número de posiciones que corresponde a los días con
%datos de la primera observación (hora=0 min=0)a la última (hora=23 min=59)
pos_ord = (1:1:(num_dias*24*num_obs))'; % vector de posiciones completo
fecha_num_min = pos_ord+date_ini_min-1; %vetor de fechas en minutos
fecha_num = fecha_num_min./(24*num_obs); % vector de fechas en días

lines = numel(fecha_num);

%Vectores con los días de entrada completos (macizos)
GHIord(1:lines,1) = NaN;
DNIord(1:lines,1) = NaN;
DHIord(1:lines,1) = NaN;

% ASIGNACIÓN DE LOS VALORES DISPONIBLES 
% A LAS POSICONES QUE LES CORRESONDEN
% EN LA MATRIZ MACIZA
%
%vector de FECHAS DE LOS DATOS DE ENTRADA en minutos, 
%menos el primer instante del de salida
%mas 1 para convertirlo en posiciones relativas 
pos_min_INI = date_num_min-fecha_num_min(1)+1;

% search the positions out HIGER lines and remove it
% AFTER = find( pos_min_INI > lines );
% pos_min_INI(AFTER) = [];
% GHI(AFTER) = []; DNI(AFTER) = []; DHI(AFTER) = [];
% 
%OJO, COMENTO EN JUL2016 P90
% % search the positions out LOWER lines and remove it
% BEFORE = find( pos_min_INI < 1 );
% pos_min_INI(BEFORE) = [];
% GHI(BEFORE) = []; DNI(BEFORE) = []; DHI(BEFORE) = [];

% ASIGNACIÓN DE LOS VALORES A FECHAS CALCULADAS 
GHIord(pos_min_INI) = GHI; % in ZoneH
DNIord(pos_min_INI) = DNI; % in ZoneH
DHIord(pos_min_INI) = DHI; % in ZoneH

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CÁCULOS ASTRONÓMICOS
% entradas calcula_astro:
%       fecha_num: vectro de fechas de cálculo
%       etiq: 0 inicio del intervalo; 0.5 centro; 1 fin 
%       num_obs:_ número de observaciones por hora
%       time: 'TSV' ó 'UTC+0' ó 'UTC+1'....
% [astro,tsv_num,UTC_num] = astro_JUN_2015...
%     (fecha_num,etiq,num_obs,time,lat,lon,ofset_empirico);
[astro,tsv_num,UTC_num]=calcula_astro_may_2015...
    (fecha_num,etiq,num_obs,time,lat,lon,ofset_empirico);
dj  =   astro(:,1);
e0  =   astro(:,2);
ang_dia=astro(:,3);
et  =   astro(:,4);
tsv_horas =astro(:,5);
w   =   astro(:,6);
dec =   astro(:,7);
cosz=   astro(:,8);
i0  =   astro(:,9);
m   =   astro(:,10);

% There must be a problem with UTC convcersion in  astro function!!

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONTROL DE CALIDAD (BSRN)
%
% PROCEDIMIENTO 1 ---------------------------------------
% SE DEFINEN DOS GRUPOS DE DATOS
% bajos: alturas solares de hasta 10 grados
%        válidos para procedimient 1 y 2
% y todos los demás
%
% Inicializando
eGHI = zeros(size(GHIord)); 
eDNI = zeros(size(DNIord));
eDHI = zeros(size(DHIord)); 

% Haciendo los grupos de datos
bajos = find( ((acos(cosz)*180/pi)>=90));

% Calculando los límites de todas las variables y grupos 
maxG = Isc.*e0*1.5.*(((cosz).^12).^0.1)+100;
maxG(bajos) = 100; % maximo fijo en este caso
maxB = Isc.*e0;    
maxD = Isc.*e0*0.95.*(((cosz).^12).^0.1)+50;
maxD(bajos) = 50;

% Asignación
proc1 = (GHIord>=-4 & GHIord<=maxG);   eGHI(proc1) = 1; clear proc1
proc1 = (DNIord>=-4 & DNIord<=maxB);   eDNI(proc1) = 1; clear proc1
proc1 = (DHIord>=-4 & DHIord<=maxD);   eDHI(proc1) = 1; clear proc1
clear  maxG maxB maxD 

% PROCEDIMIENTO 2 ---------------------------------------

% Calculando los límites de todas las variables y grupos 
maxG = Isc.*e0*1.2.*(((cosz).^12).^0.1)+50;
maxG(bajos) = 50;
maxB = Isc.*e0*0.95.*(((cosz).^2).^0.1)+10; 
maxB(bajos) = 10; 
maxD = Isc.*e0*0.75.*(((cosz).^12).^0.1)+30;
maxD(bajos) = 30;

% Selección ----------------- y -----------------Asignación
proc2 = (GHIord>=-2 & GHIord<=maxG & eGHI==1);   eGHI(proc2) = 2; clear proc2
proc2 = (DNIord>=-2 & DNIord<=maxB & eDNI==1);   eDNI(proc2) = 2; clear proc2
proc2 = (DHIord>=-2 & DHIord<=maxD & eDHI==1);   eDHI(proc2) = 2; clear proc2
% clear maxG maxB maxD

% PROCEDIMIENTO 3 ---------------------------------------
% Para los valores de las variables en los que no se puede aplicar este
% procedimiento, se imponen las condiciones del procdimiento 2.
% SE DEFINEN TRES GRUOS DE DATOS
% bajos: alturas solares a -3 a 15; GHI may. 50
% altos: alturas solares a may. 15; GHI may. 50
% y todos los demás

% CONDICIÓN PREVIA IMPUESTA A LA DIFUSA
% inicilizo una nueva variable temporal para la condicion previa
eeDHI = eDHI;
% Haciendo los grupos de datos CON LOS DATOS DE GHI ENTRADA
altos = find(((acos(cosz)*180/pi)<75) & GHIord>50);
bajos = find( ((acos(cosz)*180/pi)>=75) & ((acos(cosz)*180/pi)<93) & GHIord>50);
% Calculando límites
maxD(altos) = 1.05.*GHIord(altos);
maxD(bajos) = 1.10.*GHIord(bajos);
% Selección ----------------- y -----------------Asignación
proc31 = (DHIord<=maxD & eDHI==2 & eGHI==2 & eDNI==2); eeDHI(proc31)=3; clear proc31
clear altos bajos

GHIcalc = DNIord.*cosz+DHIord;

% CONDICIÓN GENERAL IMPUESTA A LAS TRES VARIABLES
% Haciendo los grupos de datos CON LOS DATOS DE GHI calculados?
altos = find(((acos(cosz)*180/pi)<75) & GHIcalc>50);
bajos = find(((acos(cosz)*180/pi)>=75) & ((acos(cosz)*180/pi)<93) & GHIcalc>50);
% Calculando límites
maxG(altos) = 1.08.*GHIcalc(altos);
maxG(bajos) = 1.15.*GHIcalc(bajos);
minG = zeros(size(DHIord))-2; 
minG(altos) = 0.92.*GHIcalc(altos);
minG(bajos) = 0.85.*GHIcalc(bajos);
% Selección ----------------- y -----------------Asignación
proc3 = (GHIord>=minG & GHIord<=maxG & eGHI==2 & eDNI==2 & eeDHI==3);    
eGHI(proc3) = 3; 
eDNI(proc3) = 3; 
eDHI(proc3) = 3; 
clear  proc31 altos bajos

% ME INVENTO UN PROCEDIMIENTO 4: se estaban colando valores imposibles
proc4 = ((GHIord+50 > GHIcalc & GHIord-50 < GHIcalc ) & proc3);    
eGHI(proc4) = 4; 
eDNI(proc4) = 4; 
eDHI(proc4) = 4; 

% Guardamos los resultados
eGHIF=eGHI; eDNIF=eDNI; eDHIF=eDHI;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%REPRESENTACIÓN DE RESULTADOS DEL CONTROL DE CALIDAD    
%---------------------------------------------------------------
% COHERENCIA DE LAS TRES VARIABLES
proc0 = eGHI == 0;
proc1 = eGHI == 1;
proc2 = eGHI == 2;
proc3 = eGHI == 3;
proc4 = eGHI == 4;
ceros  =0*ones(size(GHIord));
unos   =1*ones(size(GHIord));
doses  =2*ones(size(GHIord));
treses =3*ones(size(GHIord));
cuatros=4*ones(size(GHIord));

figure
plot(GHIord(proc0),GHIcalc(proc0),'o', 'MarkerFaceColor',[1   0   0  ],'MarkerEdgeColor',[ 0.8 0   0  ]);
hold on
plot(GHIord(proc1),GHIcalc(proc1),'o', 'MarkerFaceColor',[1   0.5 0  ],'MarkerEdgeColor',[ 0.8 0.3 0  ]);
plot(GHIord(proc2),GHIcalc(proc2),'o', 'MarkerFaceColor',[1   1   0  ],'MarkerEdgeColor',[ 0.8 0.8 0  ]);
plot(GHIord(proc3),GHIcalc(proc3),'o', 'MarkerFaceColor',[0.5 1   0.5],'MarkerEdgeColor',[ 0.3 0.8 0.3]);
plot(GHIord(proc4),GHIcalc(proc4),'o', 'MarkerFaceColor',[0   0.8 0  ],'MarkerEdgeColor',[ 0 0.7   0  ]);
plot([0 max_fig],[0 max_fig],'-k');
leg=legend('NaN','Not FP','Rare','Coher','Best');
set(leg,'Location','SouthEast');
axis([0 max_fig 0 max_fig]);
%title([file_name ' Consistency ' ],'Fontsize',16);

title([file_name],'Fontsize',16);
xlabel('GHI Measures','Fontsize',14,'FontWeight','bold');
ylabel('GHI calculated','Fontsize',14,'FontWeight','bold');
grid on;
axis square
set(gca,'XTick',[0:400:max_fig]);
set(gca,'YTick',[0:400:max_fig]);
% saveas(gcf,strcat(ruta_fig,'\',file_name,'_COHER'),'png');
print('-djpeg','-zbuffer','-r350',strcat(ruta_fig,'\',file_name,'_COHER'))

tsv_vec=datevec(tsv_num);

ruta_fig_mes=strcat(ruta_fig,'\Monthly');
[s,mess,messid] = mkdir(ruta_fig_mes);

clear proc0 proc1 proc2 proc3

for mes=1:12
      datos_mes=(tsv_vec(:,2) == mes );
      mes_str=num2str(mes);
      if mes<10 mes_str=['0' num2str(mes)]; end
      proc0 = (eGHI == 0 & datos_mes);
      proc1 = (eGHI == 1 & datos_mes);
      proc2 = (eGHI == 2 & datos_mes);
      proc3 = (eGHI == 3 & datos_mes);
      proc4 = (eGHI == 4 & datos_mes);
      figure
        plot(GHIord(proc0),GHIcalc(proc0),'o', 'MarkerFaceColor',[1   0   0  ],'MarkerEdgeColor',[ 0.8 0   0  ]); hold on
        plot(GHIord(proc1),GHIcalc(proc1),'o', 'MarkerFaceColor',[1   0.5 0  ],'MarkerEdgeColor',[ 0.8 0.3 0  ]);
        plot(GHIord(proc2),GHIcalc(proc2),'o', 'MarkerFaceColor',[1   1   0  ],'MarkerEdgeColor',[ 0.8 0.8 0  ]);
        plot(GHIord(proc3),GHIcalc(proc3),'o', 'MarkerFaceColor',[0.5 1   0.5],'MarkerEdgeColor',[ 0.3 0.8 0.3]);
        plot(GHIord(proc4),GHIcalc(proc4),'o', 'MarkerFaceColor',[0   0.8 0  ],'MarkerEdgeColor',[ 0 0.7   0  ]);

        plot([0 max_fig],[0 max_fig] ,'-k');

        axis([0 max_fig 0 max_fig]);
        title([file_name ' Month ' mes_str ' Consistency ' ],'Fontsize',16);
        xlabel('GHI Measures','Fontsize',16);
        ylabel('GHI calculated','Fontsize',16);
        grid on;
%     saveas(gcf,strcat(ruta_fig_mes,'\',file_name,'_COHER_M',mes_str),'png');
    print('-djpeg','-zbuffer','-r350',strcat(ruta_fig_mes,'\',file_name,'_COHER_M',mes_str))

end
%---------------------------------------------------------------
% MAPAS DE CALIDAD ANUALES
% % PEQUEÑA TRAMPA PARA QUE TODAS LAS IMÁGGENES TENGAN LOS 5 VALORES!!
% eGHI(1)=-1; eGHI(2)=0; eGHI(3)=1; eGHI(4)=2; eGHI(5)=3;
% eDNI(1)=-1; eDNI(2)=0; eDNI(3)=1; eDNI(4)=2; eDNI(5)=3;
% eDHI(1)=-1; eDHI(2)=0; eDHI(3)=1; eDHI(4)=2; eDHI(5)=3;

% Datos genéricos sobre horas de salida / mediodia / puesta de Sol
% identifica la posición de w dependiendo del num_obs (0.26rad= 1hora)
deltat=0.26/num_obs;
% w/deltat
ws = acos(-tan(dec).*tan(lat_rad));
wp = -ws;       
pos_salida = (floor(ws/deltat) == floor(w/deltat));
pos_puesta = (round(wp/deltat) == round(w/deltat));
pos_cero   = (round(w/deltat)  == 0);

valores_dia = 24*num_obs;
matrizWS = reshape(pos_salida,valores_dia,[]);
matrizWP = reshape(pos_puesta,valores_dia,[]);
matrizW0 = reshape(pos_cero,valores_dia,[]);

[y1, x1] = find(matrizWS);
[y2, x2] = find(matrizWP);
[y3, x3] = find(matrizW0);

% FIGURA ANUAL DE LA GLOBAL
if var(1)==1
    matrizGHI = reshape(eGHI,valores_dia,[]);
    figure
    if dj(1)>1
        auxiliar = zeros(24*num_obs,dj(1)-1);
        figureGHI=[auxiliar matrizGHI];
        imagesc(figureGHI);
    else
        imagesc(matrizGHI);
    end
    colormap(Micolormap)
    labels = {'0','1','2','3','4'};
    lcolorbar(labels);
    axis([0 366 0 24*num_obs]);
    title([file_name ' GHI'],'Fontsize',16);
    xlabel('Days','Fontsize',14);
    ylabel('# daily observations','Fontsize',14);
    hold on
    plot(x1,y1,'oc');
    plot(x2,y2,'oc');
    plot(x3,y3,'oc');
    print('-djpeg','-zbuffer','-r350',strcat(ruta_fig,'\',file_name,'_GHI'))

end

% FIGURA ANUAL DE LA DIRECTA
if var(2)==1
    matrizDNI = reshape(eDNI,valores_dia,[]);
    figure
    if dj(1)>1
        auxiliar = zeros(24*num_obs,dj(1)-1);
        figureDNI=[auxiliar matrizDNI];
        imagesc(figureDNI);
    else
        imagesc(matrizDNI);
    end
    colormap(Micolormap)
    labels = {'0','1','2','3','4'};
    lcolorbar(labels);
    axis([0 366 0 24*num_obs]);
    title([file_name ' DNI'],'Fontsize',16);
    xlabel('Days','Fontsize',14);
    ylabel('# daily observations','Fontsize',14);
    hold on
    plot(x1,y1,'oc');
    plot(x2,y2,'oc');
    plot(x3,y3,'oc');
    print('-djpeg','-zbuffer','-r350',strcat(ruta_fig,'\',file_name,'_DNI'))

end

% FIGURA ANUAL DE LA DIFUSA
if var(3)==1
    matrizDHI = reshape(eDHI,valores_dia,[]);
    figure
    if dj(1)>1
        auxiliar = zeros(24*num_obs,dj(1)-1);
        figureDHI=[auxiliar matrizDHI];
        imagesc(figureDHI);
    else
        imagesc(matrizDHI); 
    end
    colormap(Micolormap)
    labels = {'0','1','2','3','4'};
    lcolorbar(labels);
    axis([0 366 0 24*num_obs]);
    title([file_name ' DHI'],'Fontsize',16);
    xlabel('Days','Fontsize',14);
    ylabel('# daily observations','Fontsize',14);
    hold on
    plot(x1,y1,'oc');
    plot(x2,y2,'oc');
    plot(x3,y3,'oc');
    print('-djpeg','-zbuffer','-r350',strcat(ruta_fig,'\',file_name,'_DHI'))

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%OUTPUTS
%TRATAMIENTO DE LAS FECHAS
%SALEN EN TSV
%centra el momento a ppio del intervalo (en días)
%fecha_num_out=tsv_num-time_corr-(0.5/(num_obs*24)) ; 
fecha_num_out = tsv_num+(0.5/(num_obs*24)); % ESTE ES EL DE TANZANIA 
fecha_vec_out = datevec(fecha_num_out); 
% salida = [fecha_vec_out,GHIord,eGHI,DNIord,eDNI,DHIord,eDHI];
%TRATAMIENTO DE LAS FECHAS
%SALEN EN hora local
LT_vec=datevec(fecha_num);
salida = [LT_vec GHIord eGHIF DNIord eDNIF DHIord eDHIF];
pos_nodata = (isnan(salida));
salida(pos_nodata) = -999;
datos.timedata.timezone = time;
datos.timedata.etiq = 0;
datos.matc = salida;
datos.astro = astro;

clear entrada salida
datoscc = datos;    