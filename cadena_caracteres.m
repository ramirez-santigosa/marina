function [salida]=cadena_caracteres(entrada,longitud,char_rell)
%
% Genera una cadena de caracteres de longitud fija
% - si el string de entrada es más largo:
%       trunca
% - si el string de entrada es más corto:
%       rellena con un caracter de relleno
% (L. Ramírez, abril 2013)
%
% [salida]=cadena_caracteres[entrada,longitud,char_rell]
% 
% entrada  : string de longitud indeterminada
% longitud : longitud de la cadena de salida
% relleno  : caracter de relleno

if numel(entrada)<longitud 
    relleno(1:(longitud-numel(entrada)))=char_rell;
    cadena=[entrada relleno];
else
    cadena=entrada(1:longitud);
end
salida=cadena;
