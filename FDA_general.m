% FUNCIÓN QUE CALCULA LA FDA DE CUALQUIER SERIE DE ENTRADA
% GUILLERMO IBÁÑEZ, ABRIL 2013
% LOURDES RAMÍREZ, 2015
% function [num_dias,porcentaje]=FDA_general(datos,max,num_int)
%
% ENTRADAS:
%   datos:
%   Max:
%   num_int:
% SALIDAS:
%   num_dias:
%   pOrcentaje:
%-----------------------------------------------
function [num_dias,porcentaje]=FDA_general(datos,max,num_int)


delta=max/num_int;
rangos_vector=[delta:delta:max];

for i=1:num_int
    %num_dias=0;
    %porcentaje=0;
    valores=find(datos<=rangos_vector(i));
    num_dias(i,1)=length(valores);
    porcentaje=num_dias*100/length(datos);
end
end
