function [resultado,usados,cambiados,contador,control]...
    =Cambia_dias_sube(mes,A,VMR,max_cambios,dist_dias,max_uso)

num_dias_mes=[31 28 31 30 31 30 31 31 30 31 30 31];
%Inicializamos los vectores:
% cambiados: es un vector lógico de 1 dimensión [1 a num_dias(mes)]:
%               toma valor 1: si el día ya ha sido cambiado
%               toma valor 0: si el día NO ha sido cambiado
Dias_input=A(:,1);
Dias_ord=1:num_dias_mes(mes);
cambiados=Dias_input~=Dias_ord';
    
% usados: es un vector lógico de 2 dimensiones:
%       filas: [1 a num_dias(mes)]:
%       columnas: una columna por cambio realizado:
%               toma valor 1: la fila del día usado
%               toma valor 0: si el día NO ha sido usado
pos_cambiados=find(cambiados); % posiciones de los cambiados
valores_usados=Dias_input(pos_cambiados);
usados(1:num_dias_mes(mes),1)=0;
for i=1:numel(valores_usados)
    usados(1:num_dias_mes(mes),i)=0;
    usados(valores_usados(i),i)=1;    
end
% realiza los cambios en los valores diarios necesarios para
% acercarse al valor objetivo por la iquierda
SUMA=sum(A(:,2));
lim=3; %VMR/num_dias_mes(mes); %LIMITE OPCIÓN AICIA

control=SUMA-VMR; % Diferencia entre el valor mensual de la campaña de medidas y el Valor mensual representativo
                  % Para este caso siempre es positivo
contador=0;

resultado(:,1)=A(:,1); % posiciones iniciales
resultado(:,2)=A(:,2); % valores iniciales

if control < -(lim)  %Condicion de estar por fuera del limte establecido
    while (control < -(lim) && contador<=max_cambios)
        
        contador=contador+1;
        
        col_pos_ini=(contador*2)-1;
        col_val_ini=contador*2;

        resul_filtro=resultado(:,col_val_ini).*~cambiados; % Paso intermedio para borrar el cero y no tenerlo en cuenta con el min.
        resul_filtro(resul_filtro==0)=999;
        [minimo,posicionmin]=min(resul_filtro(resul_filtro~=0));  % Valor minimo de radiación y su posicion 
        pos_prim=posicionmin(1)-dist_dias;
        pos_ultm=posicionmin(1)+dist_dias;
        if pos_prim<=0     %asumimos que el vector de entrada solo tiene el num de dias del mes
            pos_prim=1;
        end
        if pos_ultm>=num_dias_mes(mes) 
            pos_ultm=num_dias_mes(mes);
        end
        posiciones=(pos_prim:1:pos_ultm); %vector con el trocito de las posiciones posibles
        posiciones_logicas(1:num_dias_mes(mes),1)=0; %inicilizamos vector lógico de todo el mes a ceros
        posiciones_logicas(posiciones,1)=1; %vector lógico con 1 en las posibles de cambio posibles
        
        poco_usados=(sum(usados,2)<max_uso); %Suma de los valores logicos de la fila que no pueden ser mas de 4
        
        %sentencia del millón!!
        % Vector lógico que tiene en cuenta:
        % a: que estén entre los +-n días permitidos
        % b: que no haya sido cambiado anterioremente el día
        % c: que no se haya usado ya el máximo de veces
        posibles=posiciones_logicas.*~cambiados.*poco_usados;
               
        if sum(posibles)==0
            fprintf('Not possible possitions. Contador: %d \n',contador); 
            break
        end

        valores_posibles=resultado(:,col_val_ini);   % A(posiciones,2);
        incremento=(valores_posibles-resultado(posicionmin,col_val_ini));
        falta= (abs(incremento+control)).*posibles;  % el control es negativo, si posibles=0 ese valor no se tiene en ciuenta 
                                               % y entonces aqui solo quedan los dias cercanos
        optimo=min(falta(falta~=0));
        TEMP=find(falta==optimo);% se elige el valor por el cual reemplazar el minimo que se aproxima mas a cero
        pos_optimo=TEMP(1);       % Encuentra la posicion del valor a reemplazar en el vector falta
          
        col_pos_fin=contador*2+1;
        col_val_fin=contador*2+2;
        
        % inicilización de las dos columnas de salida, 
        % con los valores de entrada
        resultado(:,col_pos_fin)=resultado(:,col_pos_ini); % posiciones iniciales
        resultado(:,col_val_fin)=resultado(:,col_val_ini); % valores iniciales
        
        %sustituimos el dato de la posición cambiada, en la colimna de las
        %posiciones de salida
        resultado(posicionmin,col_pos_fin)=...
            resultado(pos_optimo,col_pos_ini); % posición sustituida
        %sustituimos el dato del valor cambiado, en la colimna de las
        %posiciones de salida        
        resultado(posicionmin,col_val_fin)=...
            resultado(pos_optimo,col_val_ini); % valor sustituido
        
        SUMA=sum(resultado(:,col_val_fin));
        control=(SUMA-VMR);
        
        cambiados(posicionmin,1)=1;
        
        usados(:,contador)=0;
        usados(pos_optimo,contador)=1;
    end
end
