function [diarios,mensuales,cambios,cambios_mes]=...
    valida_meses(entrada,huecos)

% Función para la validación de meses de los datos de un año
% ENTRADAS:
%    salida de la validación diaria: 6 columnas por año de datos:
%      Los años son de 365 días.
%      Col1: día juliano;	
%      Col2: valor diario de radiación global  
%      Col3: validez del día de global(1/0)
%      Col4: día juliano;	
%      Col5: valor diario de DNI 
%      Col6: validez del día de DNI(1/0)

%   huecos:  máximo de días no válidos permitido
%
% SALIDAS:
%   diarios    (6 col):  radiación diaria por si actualizado
%   mensuales  (6 col):  radiación mensual /NaN si no válido
%
%       6 columnas =[dia\mes valorGHI etiqGHI dia\mes valorDNI etiqDNI ]
%
%   cambiados: matriz de 4 columnas:  [año mes dia_ini dia_fin]
%-----------------------------------------------------------------------
% 
% dependiendo de los huecos permitidos de días en mes (hasta 4)
% el valor del hueco se sustituye por el del día más parecido a la media

num_dias=[31 28 31 30 31 30 31 31 30 31 30 31];
num_dias_antes=[0 31 28 31 30 31 30 31 31 30 31 30];

%le damos a los días de salida, la dimensión de entrada
diarios=entrada;
%inicializamos los días de salida
diarios(:,:)=NaN;
mensuales(1:12,1)=NaN;

num=0; % num de cambios
cambios=[];
cambios_mes=[];

for mes=1:12
    clear dias RAD eRAD
    %determinación de las filas de inicio y final de cada mes
    ini=1+sum(num_dias_antes(1:mes));
    fin=ini+num_dias(mes)-1;
    
    %identificación de los trozos de cada mes
    %dia del mes
    dias=entrada(ini:fin,1);
 
    %radiación global y su etiqueta
    GHI=entrada(ini:fin,2)/1000;
    eGHI=entrada(ini:fin,3); 
    
    %radiación directa y su etiqueta
    DNI=entrada(ini:fin,5)/1000;
    eDNI=entrada(ini:fin,6); 
    
    %NOS CENTRAMOS EN EL ANÁLISIS DE LA DNI
    % es raro, pero posible valores diarios ==0
    pos_faltanDNI=find(eDNI==0);
    DNI(pos_faltanDNI)=NaN;
    num_faltanDNI=numel(pos_faltanDNI);
    
    %VEMOS LOS RESULTADOS EN GLOBAL
    % no es posible valores diarios ==0
    pos_faltanGHI=find( eGHI==0 | GHI==0);
    GHI(pos_faltanGHI)=NaN;
    num_faltanGHI=numel(pos_faltanGHI);
    
    %Si NO faltan días válidos EN DNI
    if num_faltanDNI==0
        %la mensual es la suma de las diarias
        rad_mesDNI=sum(DNI);
        e_valDNI=1;
        
        % SOLUCIONAMOS LA GLOBAL
        if num_faltanGHI==0
            %la mensual es la suma de las diarias
            rad_mesGHI=sum(GHI);
            e_valGHI=1;
        else
            %Caso en el que estan todos los dias de DNI, pero falta alguno
            %de GHI. NO se puede sustituir la GHI.
            rad_mesGHI=NaN;
            e_valGHI=3;
        end
        
    %Si SI FALTAN días válidos EN DNI
    else
        if num_faltanDNI<=huecos && num_faltanDNI>=1
            %determina los válidos
            validos=find(~isnan(DNI));
            %calcula la media mensual de los validos
            rad_med=sum(DNI(validos))/numel(validos);
            %posición del día con valor más cercano a la media
            minima_dist=min(abs(DNI-rad_med));
            pos_med=find(abs(DNI-rad_med)==minima_dist);

            %sustituye los dias que faltan por el mas cercano a la media
            dias(pos_faltanDNI)=dias(pos_med(1));
            DNI(pos_faltanDNI)=DNI(pos_med(1));
            %la mensual es la suma de las diarias
            rad_mesDNI=sum(DNI);
            e_valDNI=1;
            
            % SOLUCIONAMOS LA GLOBAL
            %Buscamos dias válidos de GHI en las posiciones de los válidos
            % se exige que el valor de GHI sea distinto de 0
            % de DNI
            valGHI=(find(~isnan(GHI(validos))& GHI(validos)~=0));
            if numel(valGHI)==numel(validos)
                %hay que hacer los cambos que se hicieron en DNI
                %sustituye los dias que faltaban en DNI
                %con el valor de la posición del día de DNI más cercano a la Med. Mens,
                %de DNI, que lo teniamos calculado de antes "pos_med(1)"
                GHI(pos_faltanDNI)=GHI(pos_med(1));
                %la mensual es la suma de las diarias
                rad_mesGHI=sum(GHI);
                e_valGHI=1;
            else
                %Caso en el que falta alguno de GHI. NO se puede sustituir la GHI.
                rad_mesGHI=NaN;
                e_valGHI=5;
            end
            
            %identifica los cambios
            for k=1:numel(pos_faltanDNI)
                num=num+1;
                cambios(num,1)=mes;
                %dia de origen
                cambios(num,2)=dias(pos_med(1));
                %dia de fin
                cambios(num,3)=pos_faltanDNI(k);
            end
        else
            rad_mesDNI=NaN;  
            e_valDNI=0;
            rad_mesGHI=NaN;  
            e_valGHI=7;
        end
    end
    
    num_cambios=numel(pos_faltanDNI);
    cambios_mes(mes,1)=num_cambios;

    diarios(ini:fin,1)=dias;
    diarios(ini:fin,2)=GHI*1000;
    diarios(ini:fin,3)=eGHI;
    diarios(ini:fin,4)=dias;
    diarios(ini:fin,5)=DNI*1000;
    diarios(ini:fin,6)=eDNI;
    
    mensuales(mes,1)=mes;
    mensuales(mes,2)=rad_mesGHI;
    mensuales(mes,3)=e_valGHI;
    mensuales(mes,4)=mes;
    mensuales(mes,5)=rad_mesDNI;
    mensuales(mes,6)=e_valDNI;
end   