function [salida_obs,eti,diaria,e_val]=valida_dias(pos_dia,dat,eti,num_obs,level,dj)
% Función que evalua la validez de los datos horarios de entrada
%
% ENTRADAS:
%   pos_dia: booleano de los datos entre la salida y la puesta de sol
%   dat:     vector con datos de radición 
%   eti:     vector con  datos de la calidad de los datos de radición 
%            (0:no valido; 1:raro pero posible; 2:posible y no raro; 3:estupendo)
% SALIDAS:
%   salida_obs: serie de valores, por si se ha interpolado
%   diaria:  valor de la radiación diaria /NaN si no válido
%   e_val: etiqueta de la validación 1 dia válido; 0 día no válido
%-----------------------------------------------------------------------

valids= (eti>= level ...      
       & ~isnan(dat) ...      %si no es NaN la radiación solar
       & dat~=-999)  ...      %si no es -999 la radiación solar
       & pos_dia;             %en las posiciones del día solar 

% look for the sunset in pos_dia
val_pos_dia = find(pos_dia);
val_pos_before_sunrise = val_pos_dia(1)-1;
val_pos_after_sunset   = val_pos_dia(end)+1;

valids(val_pos_before_sunrise) = 1;
valids(val_pos_after_sunset)   = 1;
dat(val_pos_before_sunrise)    = 0;
dat(val_pos_after_sunset)      = 0;
   
bads= pos_dia & ~valids;

if sum(valids)>2 % two have been added
    if sum(bads)==0
        diaria=round(sum(dat(pos_dia)))/num_obs;
        e_val=1;
    else
        if sum(bads) <= num_obs
        secuence_day= (1:1440)';  
        dat(bads) = interp1(secuence_day(valids),dat(valids),secuence_day(bads));
        eti(bads) = 2;
        %podemos seguir sumando los datos  para calcular el diario
        diaria=round(sum(dat(pos_dia))/num_obs);
        %asigno el código de validez a la etiqueta diaria
        e_val=1;
            
        else
            diaria=NaN;
            e_val=0;
        end
    end
else
    diaria=NaN;
    e_val=0;
end
if ( e_val==1 & diaria~=0)
    e_val=2;
end
salida_obs(1:24*num_obs)=0;
salida_obs(pos_dia)=dat(pos_dia);