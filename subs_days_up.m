function [result,origin,replaced,counter,ctrl]...
    = subs_days_up(month,days_m,RMV,limit,max_dist,max_times,max_subs)
%SUBS_DAYS_UP Carry out days substitutions to increment the monthly value
%towards the Representative monthly value (RMV).
%   INPUT:
%   month: Number of the evaluated month.
%   days_m: Number of the day and daily irradiance in kWh/m2.
%   RMV: Representative long term monthly value (objective value).
%   max_dist: Maximum distance in the days used for the substitution
%   (+-max_dist).
%   max_times: Maximum number of times that the same day may appear in the
%   generated data set.
%   max_subs: Maximum number of substitutions allowed each month.
%
%   OUTPUT:
%   result: aaa
%
% - F. Mendoza (May 2017) Update

num_days_m = [31 28 31 30 31 30 31 31 30 31 30 31]; % Number of days in each month (no leap years)

%Inicializamos los vectores:
% cambiados: es un vector lógico de 1 dimensión [1 a num_dias(mes)]:
%               toma valor 1: si el día ya ha sido cambiado
%               toma valor 0: si el día NO ha sido cambiado
Dias_input=days_m(:,1);
Dias_ord=1:num_days_m(month);
replaced=Dias_input~=Dias_ord';

% usados: es un vector lógico de 2 dimensiones:
%       filas: [1 a num_dias(mes)]:
%       columnas: una columna por cambio realizado:
%               toma valor 1: la fila del día usado
%               toma valor 0: si el día NO ha sido usado
pos_cambiados=find(replaced); % posiciones de los cambiados
valores_usados=Dias_input(pos_cambiados);
origin(1:num_days_m(month),1)=0;
for i=1:numel(valores_usados)
    origin(1:num_days_m(month),i)=0;
    origin(valores_usados(i),i)=1;
end
% realiza los cambios en los valores diarios necesarios para
% acercarse al valor objetivo por la iquierda
SUMA=sum(days_m(:,2));

ctrl = SUMA-RMV; % Diferencia entre el valor mensual de la campaña de medidas y el Valor mensual representativo
% Para este caso siempre es positivo
counter = 0;

result(:,1)=days_m(:,1); % posiciones iniciales
result(:,2)=days_m(:,2); % valores iniciales

if ctrl < -(limit)  %Condicion de estar por fuera del limte establecido
    while (ctrl < -(limit) && counter<=max_subs)
        
        counter=counter+1;
        
        col_pos_ini=(counter*2)-1;
        col_val_ini=counter*2;
        
        resul_filtro=result(:,col_val_ini).*~replaced; % Paso intermedio para borrar el cero y no tenerlo en cuenta con el min.
        resul_filtro(resul_filtro==0)=999;
        [minimo,posicionmin]=min(resul_filtro(resul_filtro~=0));  % Valor minimo de radiación y su posicion
        pos_prim=posicionmin(1)-max_dist;
        pos_ultm=posicionmin(1)+max_dist;
        if pos_prim<=0     %asumimos que el vector de entrada solo tiene el num de dias del mes
            pos_prim=1;
        end
        if pos_ultm>=num_days_m(month)
            pos_ultm=num_days_m(month);
        end
        posiciones=(pos_prim:1:pos_ultm); %vector con el trocito de las posiciones posibles
        posiciones_logicas(1:num_days_m(month),1)=0; %inicilizamos vector lógico de todo el mes a ceros
        posiciones_logicas(posiciones,1)=1; %vector lógico con 1 en las posibles de cambio posibles
        
        poco_usados=(sum(origin,2)<max_times); %Suma de los valores logicos de la fila que no pueden ser mas de 4
        
        %sentencia del millón!!
        % Vector lógico que tiene en cuenta:
        % a: que estén entre los +-n días permitidos
        % b: que no haya sido cambiado anterioremente el día
        % c: que no se haya usado ya el máximo de veces
        posibles=posiciones_logicas.*~replaced.*poco_usados;
        
        if sum(posibles)==0
            fprintf('Not possible possitions. Contador: %d \n',counter);
            break
        end
        
        valores_posibles=result(:,col_val_ini);   % A(posiciones,2);
        incremento=(valores_posibles-result(posicionmin,col_val_ini));
        falta= (abs(incremento+ctrl)).*posibles;  % el control es negativo, si posibles=0 ese valor no se tiene en ciuenta
        % y entonces aqui solo quedan los dias cercanos
        optimo=min(falta(falta~=0));
        TEMP=find(falta==optimo);% se elige el valor por el cual reemplazar el minimo que se aproxima mas a cero
        pos_optimo=TEMP(1);       % Encuentra la posicion del valor a reemplazar en el vector falta
        
        col_pos_fin=counter*2+1;
        col_val_fin=counter*2+2;
        
        % inicilización de las dos columnas de salida,
        % con los valores de entrada
        result(:,col_pos_fin)=result(:,col_pos_ini); % posiciones iniciales
        result(:,col_val_fin)=result(:,col_val_ini); % valores iniciales
        
        %sustituimos el dato de la posición cambiada, en la colimna de las
        %posiciones de salida
        result(posicionmin,col_pos_fin)=...
            result(pos_optimo,col_pos_ini); % posición sustituida
        %sustituimos el dato del valor cambiado, en la colimna de las
        %posiciones de salida
        result(posicionmin,col_val_fin)=...
            result(pos_optimo,col_val_ini); % valor sustituido
        
        SUMA=sum(result(:,col_val_fin));
        ctrl=(SUMA-RMV);
        
        replaced(posicionmin,1)=1;
        
        origin(:,counter)=0;
        origin(pos_optimo,counter)=1;
    end
end

end
